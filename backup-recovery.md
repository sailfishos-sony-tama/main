# Backup and recovery

This port provides the backup and recovery to SDCard using [FSArchiver](https://www.fsarchiver.org/). While other ports have TWRP for making 
snapshot of the installed system, TWRP does not support LVM which is used in Tama and official devices.

General approach is to backup root and home partitions. The other partitions can be restored by flashing corresponding Sailfish release
before recovering the backup.

## Requirements

You will need 

* PC with USB2 port and USB cable
* Ability to boot into recovery, see [Fastboot instructions](https://github.com/sailfishos-sony-tama/main/blob/master/hadk-sony-xz2.md#fastboot)
* MicroSD card for keeping backups
* Know hot to use FSArchiver, see [quick start](https://www.fsarchiver.org/quickstart)

The rest of these instructions assumes that you have setup PC and can login into recovery after booting into it by fastboot.

## Backup

1. Establish telnet connection to the device in recovery

2. In recovery mode, select "Shell without mounting anything"

Now you should get a shell prompt in your telnet session. Until stated, the rest are commands in that session.

3. Create folder for mounting your SD card filesystem:

```
mkdir /sdcard
```

4. Mount SD card. Notice that the command below is using Sony Tama disk names. Those could be different on other devices. 
If you use these instructions for other devices, **check which partition corresponds to SD card**.
```
mount /dev/mmcblk0p1 /sdcard
```

5. Activate LVM and check that info is correct

```
lvm vgchange -a y
lvm lvdisplay
ls -lh /dev/sailfish
```

6. Set environment variable with the backup folder name. Adjust the folder name as needed:
```
export BCKP=/sdcard/backup/sfos-3.3.0.16-2020.07.18
```

7. Create a folder for keeping the new backup. Adjust the name of the folder as needed:
```
mkdir -p $BCKP
```

8. Backup the data. While FSArchiver can keep several filesystems in a single archive, here filesystems are stored separately. Backup
is performed using two threads (-j2), lower compression level (-z2), and verbose output.

```
fsarchiver savefs $BCKP/rootfs.fsa /dev/sailfish/root -v -j2 -z2 -a
fsarchiver savefs $BCKP/homefs.fsa /dev/sailfish/home -v -j2 -z2 -a
```

9. Check the archives:
```
ls -lh $BCKP
fsarchiver archinfo $BCKP/rootfs.fsa
fsarchiver archinfo $BCKP/homefs.fsa
```

10. Unmount backup filesystem and deactivate LVM
```
umount /sdcard
lvm vgchange -a n
```

11. Exit shell by pressing Ctrl-D

12. Reboot phone when asked for it by recovery tool.


## Restoring

1. If you need to restore all partitions, including boot and others, flash the corresponding Sailfish OS release first. After flashing, boot into
Sailfish OS. Do not login into the Store, just proceed until you get into user UI. After that, shutdown the phone

2. Get into recovery mode

3. In recovery mode, select "Shell without mounting anything"

4. Create folder for mounting your SD card filesystem:

```
mkdir /sdcard
```

5. Mount SD card. Notice that the command below is using Sony Tama disk names. Those could be different on other devices. 
If you use these instructions for other devices, **check which partition corresponds to SD card**.
```
mount /dev/mmcblk0p1 /sdcard
```

6. Activate LVM and check that info is correct

```
lvm vgchange -a y
lvm lvdisplay
ls -lh /dev/sailfish
```

7. List available backups and set environment variable with the backup folder name:
```
ls -l /sdcard/backup/
export BCKP=/sdcard/backup/sfos-3.3.0.16-2020.07.18
```

8. As FSArchiver requires full e2fsutils and does not work with BusyBox mke2fs (missing options),
we have to reconfigure the environment accordingly:
```
mv /bin/mke2fs /bin/mke2fs.old
ln -s /sbin/mkfs.ext4 /bin/mke2fs
```

9. Resore the data. While FSArchiver can keep several filesystems in a single archive, here filesystems are stored separately.
Adjust the options if needed.
```
fsarchiver restfs $BCKP/rootfs.fsa id=0,dest=/dev/sailfish/root -v
fsarchiver restfs $BCKP/homefs.fsa id=0,dest=/dev/sailfish/home -v
```

10. Unmount backup filesystem and deactivate LVM
```
umount /sdcard
lvm vgchange -a n
```

11. Exit shell by pressing Ctrl-D

12. Reboot phone when asked for it by recovery tool.
