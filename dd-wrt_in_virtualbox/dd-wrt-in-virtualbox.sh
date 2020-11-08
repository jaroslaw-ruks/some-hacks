#!/bin/bash 
set -e
if [ -z $1 ]; then
    echo "write name of vm"
    exit
fi
function reload(){
sleep 10
vboxmanage controlvm $vm_name reset
while [ true ]; do nc 192.168.1.1 22 -vzw 5; if [ $? -eq 0 ]; then break; fi ; sleep 5 ; done
sleep 10
}
vm_name=$1
if [ ! -f ~/Downloads/dd-wrt.image ]; then
    wget -v https://download1.dd-wrt.com/dd-wrtv2/downloads/betas/2020/04-20-2020-r42954/x86_64/dd-wrt_x64_public_vga.image -O ~/Downloads/dd-wrt.image 
fi
image_path=~/Downloads/dd-wrt.image
vboxmanage createvm --name $vm_name --register;
vboxmanage modifyvm $vm_name --ostype Linux;
vboxmanage modifyvm $vm_name  --ioapic on;
vboxmanage modifyvm $vm_name  --mouse usbtablet;
vboxmanage storagectl $vm_name --name IDE --add ide --controller PIIX4 --portcount 2;
directory_path=$(vboxmanage  showvminfo $vm_name | sed -n "s/^Config\ file:\s*\(.*\)\/.*$/\1/p");
vdi_path="$directory_path/$vm_name.vdi";
VBoxManage convertdd "$image_path" --format vdi "$vdi_path";
vboxmanage modifyhd --resize 256 "$vdi_path"
VBoxManage storageattach $vm_name --storagectl "IDE" --port 0 --device 0 --type hdd --medium "$vdi_path"
echo "temporary turn off interface $(ifconfig |grep -B1 192.168.1 | awk 'NR==1{print $1}')"
hostonly=$(vboxmanage list hostonlyifs | grep "192\.168\.1\." -c || true)
if [ $hostonly -eq 0 ] ;then
	echo 'missing hostonly interface with network 192.168.1.0/24'
	echo 'create..'
	old=$(vboxmanage list  -s hostonlyifs |grep '^Name')
	vboxmanage hostonlyif create
	new=$(vboxmanage list  -s hostonlyifs |grep '^Name')
	interface=$(diff  <(echo "$new" ) <(echo "$old")| grep Name| awk '{print $NF}')
	vboxmanage hostonlyif ipconfig  --ip 192.168.1.2 --netmask 255.255.255.0 $interface 
else 
	interface=$(vboxmanage list hostonlyifs |grep "192\.168\.1\." -B3 |grep Name | awk '{print $NF}')
fi
echo $interface
vboxmanage modifyvm $vm_name --nic1 hostonly  --hostonlyadapter1 $interface
vboxmanage startvm $vm_name
set +e
sleep 60
#password
timeout 10 curl -i -s -k -X $'POST' \
    -H $'Host: 192.168.1.1' -H $'Content-Length: 168' -H $'Cache-Control: max-age=0' -H $'Upgrade-Insecure-Requests: 1' -H $'Origin: http://192.168.1.1' -H $'Content-Type: application/x-www-form-urlencoded' -H $'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36' -H $'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' -H $'Referer: http://192.168.1.1/' -H $'Accept-Encoding: gzip, deflate' -H $'Accept-Language: en-US,en;q=0.9' -H $'Connection: close' \
    --data-binary $'submit_button=index&submit_type=changepass&next_page=Info.htm&change_action=gozila_cgi&action=Apply&http_username=admin&http_passwd=password&http_passwdConfirm=password' \
    $'http://192.168.1.1/apply.cgi'
#wan config
reload
timeout 10 curl -i -s -k -X $'POST' \
    -H $'Host: 192.168.1.1' -H $'Content-Length: 1002' -H $'Cache-Control: max-age=0' -H $'Authorization: Basic YWRtaW46cGFzc3dvcmQ=' -H $'Upgrade-Insecure-Requests: 1' -H $'Origin: http://192.168.1.1' -H $'Content-Type: application/x-www-form-urlencoded' -H $'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36' -H $'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' -H $'Referer: http://192.168.1.1/index.asp' -H $'Accept-Encoding: gzip, deflate' -H $'Accept-Language: en-US,en;q=0.9' -H $'Connection: close' \
    --data-binary $'submit_button=index&action=Apply&change_action=gozila_cgi&submit_type=wan_proto&now_proto=disabled&dns_dnsmasq=0&wan_priority=0&auth_dnsmasq=0&dns_redirect=0&recursive_dns=0&fullswitch=0&ppp_mlppp=0&lan_ipaddr=4&wan_proto=dhcp&router_name=DD-WRT&wan_hostname=&wan_domain=&mtu_enable=0&sfe=1&lan_stp=0&lan_ipaddr_0=192&lan_ipaddr_1=168&lan_ipaddr_2=1&lan_ipaddr_3=1&lan_netmask=4&lan_netmask_0=255&lan_netmask_1=255&lan_netmask_2=255&lan_netmask_3=0&lan_gateway=4&lan_gateway_0=0&lan_gateway_1=0&lan_gateway_2=0&lan_gateway_3=0&sv_localdns=4&sv_localdns_0=0&sv_localdns_1=0&sv_localdns_2=0&sv_localdns_3=0&dhcpfwd_enable=0&lan_proto=dhcp&dhcp_check=&dhcp_start=100&dhcp_num=50&dhcp_lease=1440&wan_dns=4&wan_dns0_0=0&wan_dns0_1=0&wan_dns0_2=0&wan_dns0_3=0&wan_dns1_0=0&wan_dns1_1=0&wan_dns1_2=0&wan_dns1_3=0&wan_dns2_0=0&wan_dns2_1=0&wan_dns2_2=0&wan_dns2_3=0&wan_wins=4&wan_wins_0=0&wan_wins_1=0&wan_wins_2=0&wan_wins_3=0&_dns_dnsmasq=1&_auth_dnsmasq=1&ntp_enable=1&time_zone=Europe%2FBerlin&ntp_server=' \
    $'http://192.168.1.1/apply.cgi'
reload
#network
timeout 10 curl -i -s -k -X $'POST' \
    -H $'Host: 192.168.1.1' -H $'Content-Length: 984' -H $'Cache-Control: max-age=0' -H $'Authorization: Basic YWRtaW46cGFzc3dvcmQ=' -H $'Upgrade-Insecure-Requests: 1' -H $'Origin: http://192.168.1.1' -H $'Content-Type: application/x-www-form-urlencoded' -H $'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36' -H $'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' -H $'Referer: http://192.168.1.1/apply.cgi' -H $'Accept-Encoding: gzip, deflate' -H $'Accept-Language: en-US,en;q=0.9' -H $'Connection: close' \
    --data-binary $'submit_button=index&action=ApplyTake&change_action=&submit_type=&now_proto=dhcp&dns_dnsmasq=1&wan_priority=0&auth_dnsmasq=1&dns_redirect=0&recursive_dns=0&fullswitch=0&ppp_mlppp=0&lan_ipaddr=4&wan_proto=dhcp&router_name=DD-WRT&wan_hostname=&wan_domain=&mtu_enable=0&sfe=1&lan_stp=0&lan_ipaddr_0=192&lan_ipaddr_1=168&lan_ipaddr_2=10&lan_ipaddr_3=1&lan_netmask=4&lan_netmask_0=255&lan_netmask_1=255&lan_netmask_2=255&lan_netmask_3=0&lan_gateway=4&lan_gateway_0=0&lan_gateway_1=0&lan_gateway_2=0&lan_gateway_3=0&sv_localdns=4&sv_localdns_0=0&sv_localdns_1=0&sv_localdns_2=0&sv_localdns_3=0&dhcpfwd_enable=0&lan_proto=dhcp&dhcp_check=&dhcp_start=100&dhcp_num=50&dhcp_lease=1440&wan_dns=4&wan_dns0_0=0&wan_dns0_1=0&wan_dns0_2=0&wan_dns0_3=0&wan_dns1_0=0&wan_dns1_1=0&wan_dns1_2=0&wan_dns1_3=0&wan_dns2_0=0&wan_dns2_1=0&wan_dns2_2=0&wan_dns2_3=0&wan_wins=4&wan_wins_0=0&wan_wins_1=0&wan_wins_2=0&wan_wins_3=0&_dns_dnsmasq=1&_auth_dnsmasq=1&ntp_enable=1&time_zone=Europe%2FBerlin&ntp_server=' \
    $'http://192.168.1.1/apply.cgi'

sleep 10
vboxmanage controlvm $vm_name reset

sleep 60
vboxmanage controlvm $vm_name poweroff
sleep 5
vboxmanage modifyvm $vm_name --nic1 bridged --bridgeadapter1 `route  |grep default |grep -v  'tun\|tap' | awk 'NR==1{print $NF}'` --nictype2 82540EM --nicpromisc2 allow-all
vboxmanage modifyvm $vm_name --nic2 intnet --nictype2 82540EM --nicpromisc2 allow-all
vboxmanage startvm $vm_name 
vboxmanage hostonlyif remove `vboxmanage list hostonlyifs |grep "192\.168\.1\." -B3 | awk 'NR==1{print $2}'`
