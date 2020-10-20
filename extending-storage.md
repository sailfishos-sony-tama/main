# Adding unused storage to LVM

Sony Tama devices have system_a and system_b partitions with just below 4GB each. These partitions are not used in Sailfish
and can be put into use by merging them with LVM.

**This procedure is tested but dangerous. You could mess up with the partition numbers and possibly brick the device.
In this respect, think whether you actually need this extra storage before making the changes.**

On Sailfish, system_b is used to keep factory reset images. If you do not want to perform factory reset and prefer
to have this as extra storage, it is possible. system_a is not used on Sailfish at all.

Below, all commands are entered in root shell on booted phone, via ssh session. This demonstrates how to add
system_a to LVM and use it for HOME partition. Similar could be done for ROOT partition or any extra storage can
be split between partitions.

1. Reformat system_a into PV:
```Shell
pvcreate /dev/disk/by-partlabel/system_a
```
It should show up as below
```Shell
# pvdisplay

  --- Physical volume ---
  PV Name               /dev/sda73
  VG Name               sailfish
  PV Size               <47.92 GiB / not usable 592.00 KiB
  Allocatable           yes (but full)
  PE Size               4.00 MiB
  Total PE              12266
  Free PE               0
  Allocated PE          12266
  PV UUID               NJUIKf-Z5cV-0RBW-Glg3-uwaJ-2MZT-ew3sBF
 
  "/dev/sda42" is a new physical volume of "<3.94 GiB"
  --- NEW Physical volume ---
  PV Name               **/dev/sda42**
  VG Name               
  PV Size               <3.94 GiB
  Allocatable           NO
  PE Size               0   
  Total PE              0
  Free PE               0
  Allocated PE          0
  PV UUID               uNcZ6m-vKJx-GqHE-ZSrc-Gj6s-1gX6-3lMqMI
```

2. Extend `sailfish` volume group by new storage:
```Shell
vgextend sailfish /dev/disk/by-partlabel/system_a
```

`pvdisplay` and `vgdisplay` should now show that new PV is allocatable and is a part of sailfish VG, VG has free PE:
```Shell
# pvdisplay

...
  --- Physical volume ---
  PV Name               /dev/sda42
  VG Name               sailfish
  PV Size               <3.94 GiB / not usable 4.00 MiB
  Allocatable           yes 
  PE Size               4.00 MiB
  Total PE              1007
  Free PE               1007
  Allocated PE          0
  PV UUID               uNcZ6m-vKJx-GqHE-ZSrc-Gj6s-1gX6-3lMqMI

# vgdisplay

  --- Volume group ---
  VG Name               sailfish
  System ID             
  Format                lvm2
...
  Free  PE / Size       1007 / 3.93 GiB
```

3. Choose the partition that you want to extend and do so. Below, all is added to home
```Shell
lvextend -l +100%FREE /dev/sailfish/home
```

4. Resize corresponding filesystem
```Shell
resize2fs /dev/sailfish/home
```

5. Reboot

Might be a good idea to boot into Sailfish recovery and perform file system check.
