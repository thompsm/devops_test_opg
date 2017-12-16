#!/bin/bash

set -e

# Loop through the ephemeral disks, pvcreate them, and then create a list so we can add them to the VG
for edev in $(curl -s http://169.254.169.254/latest/meta-data/block-device-mapping/ | grep ephemeral)
do

  echo "Found ephemeral device ${edev}"

  # Fetch the device name
  edev_disk=$(curl -s http://169.254.169.254/latest/meta-data/block-device-mapping/${edev})
  echo "Disk device is ${edev_disk}"

  # Translate sdb to xvdb
  xdev_disk=$(echo ${edev_disk} | sed 's/^s/xv/')
  echo "Actual devices is ${xdev_disk}"

  # pvcreate the disk ready to be added to the VG
  pvcreate /dev/${xdev_disk}

  # Add the disk to the list
  vgdisks="${vgdisks} /dev/${xdev_disk}"

done

if [ "${vgdisks}" != "" ]
then

  # Create the vg from the disks
  vgcreate vg01 ${vgdisks}

  # Create the lv
  lvcreate -n lv01 -l 100%VG vg01

  # Format
  mkfs.ext4 -F /dev/mapper/vg01-lv01

  # Mount on /opt
  mount /dev/mapper/vg01-lv01 /opt

  # Add fstab entry
  echo "/dev/mapper/vg01-lv01 /opt ext4    defaults 0 0" >> /etc/fstab

else

  echo "No ephmeral disks found."

fi