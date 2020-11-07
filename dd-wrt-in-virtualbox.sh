#!/bin/bash 
set -e
set -x
if [ -z $1 ]; then
    echo "write name of vm"
    exit
fi
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
vboxmanage modifyvm $vm_name --nic1 intnet --nictype1 82540EM --nicpromisc1 allow-all
vboxmanage modifyvm $vm_name --intnet1 "dd-internal-network"
vboxmanage modifyvm $vm_name --nic2 bridged --nictype2 82540EM --nicpromisc2 allow-all
