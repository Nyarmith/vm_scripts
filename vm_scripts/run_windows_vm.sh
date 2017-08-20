#!/bin/bash

#use lsusb to find the id of your keyboard, mouse and any other devices you want to forward to the VM here
#if you want to add more, make more -usbdevice entries in the -usb section of the qemu command
mouse=0d8c:0005
keybd=046d:c332

vmname="windows10vm"
configfile=/etc/vfio-pci10.cfg

vfiobind() {
   dev="$1"
        vendor=$(cat /sys/bus/pci/devices/$dev/vendor)
        device=$(cat /sys/bus/pci/devices/$dev/device)
        if [ -e /sys/bus/pci/devices/$dev/driver ]; then
                echo $dev > /sys/bus/pci/devices/$dev/driver/unbind
        fi
        echo $vendor $device > /sys/bus/pci/drivers/vfio-pci/new_id
}

if ps -A | grep -q $vmname; then
   echo "$vmname is already running." &
   exit 1

else

cat $configfile | while read line;do
echo $line | grep ^# >/dev/null 2>&1 && continue
   vfiobind $line
done

# use pulseaudio
#export QEMU_AUDIO_DRV=pa

cp /usr/share/OVMF/OVMF_VARS.fd /tmp/my_vars.fd

qemu-system-x86_64 \
  -name $vmname,process=$vmname \
  -machine type=q35,accel=kvm \
  -cpu host,kvm=off \
  -smp 4,sockets=1,cores=4,threads=1 \
  -enable-kvm \
  -m 32G \
  -mem-path /run/hugepages/kvm \
  -mem-prealloc \
  -balloon none \
  -rtc clock=host,base=localtime \
  -vga none \
  -nographic \
  -serial none \
  -parallel none \
  -soundhw hda \
  -usb -usbdevice host:$mouse -usbdevice host:$keybd \
  -device vfio-pci,host=01:00.0,multifunction=on \
  -device vfio-pci,host=01:00.1 \
  -device ioh3420,bus=pcie.0,addr=1c.0,multifunction=on,port=1,chassis=1,id=root.1 \
  -device vfio-pci,host=03:00.0,bus=root.1,addr=00.0 \
  -drive if=pflash,format=raw,readonly,file=/usr/share/OVMF/OVMF_CODE.fd \
  -drive if=pflash,format=raw,file=/tmp/my_vars.fd \
  -boot order=cd \
  -device virtio-scsi-pci,id=scsi \
  -drive id=disk0,if=virtio,cache=none,format=raw,file=/home/reader/VM_Images/${1} \
  -drive file=/home/reader/Downloads/virtio-win-0.1.126.iso,id=virtiocd,format=raw,if=none -device ide-cd,bus=ide.1,drive=virtiocd \
  -netdev type=tap,id=net0,ifname=tap0,vhost=on \
  -device virtio-net-pci,netdev=net0

   exit 0
fi

