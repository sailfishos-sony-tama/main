# Transition from AOSP9-based Sailfish OS port

To switch from AOSP9-based Sailfish port, you would have to reflash
the device. The following procedure is suggested for the devices
switching over to this version.

## Backup

Backup all your data. I would suggest to backup your home directory
fully with whatever tools you feel comfortable with. I have used
`rsync` for it.

To make it simple to switch back if something will break badly, it is
possible to make filesystem level backups. For that, you would need
PC, SD card which is large enough to keep all your storage, and
recovery image to boot into recovery mode. See
[documentation](backup-recovery.md) on how to do that.

## Get latest stock Android

To ensure that you have the latest updates for firmware, such as modem
and bootloader, get the latest version of Sony Stock Android. You
could use
[XperiFirm](https://forum.xda-developers.com/t/tool-xperifirm-xperia-firmware-downloader-v5-6-1.2834142)
to download it and
[Newflasher](https://forum.xda-developers.com/t/tool-newflasher-xperia-command-line-flasher.3619426/)
to flash it.

Notice that Newflasher is using flash mode (not fastboot), so follow
the instructions on how to flash it.

After flashing stock, boot into it. You don't need to fully set it up,
but you would need to establish connection via SIM card and let it
update the modem if needed. So, just keep it running in Android for a
bit.

## Flashing Sailfish

Follow [flashing guide](flashing.md). Notice that you will need to
download new OEM images for AOSP10 based port.

## Going back to AOSP9 (not tested)

Note that this has not been tested, but is expected to work.

If you have filesystem-based backup, getting back to AOSP9-based port
should be simple. Flash OEM Tama image for AOSP9 and flash AOSP9-based
port latest Sailfish release. Boot into Sailfish as it will adjust LVM
filesystems. You don't need to setup anything, just skip all the setup
questions and get into the desktop. Shutdown the device after that and
get into recovery. See [documentation](backup-recovery.md) on how to
restore your backup.

