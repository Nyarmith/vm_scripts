#!/bin/bash
configfile=/etc/vfio-pci10.cfg

unbind(){
    dev="$1"
    echo 1 > /sys/bus/pci/devices/$dev/remove
}

cat $configfile | while read line;do
echo $line | grep ^# >/dev/null 2>&1 && continue
   echo $line " being unbound"
   unbind $line
done

echo "Rescanning Devices..."
echo 1 > /sys/bus/pci/rescan
