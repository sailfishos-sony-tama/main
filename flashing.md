# Flashing Sailfish on Xperia Tama device

Start with [README](README.md) in this repository. Come back after reading it.

Procedure is similar to flashing Sailfish X on Xperia 10, as described at https://jolla.com/sailfishxinstall/. 
Notable differences are

- you do not need to buy any license as you are getting ported version of Sailfish;
- software binaries would correspond to Xperia Tama;
- Xperia Tama requires vbmeta image for flashing;
- due to a bootloader bug, Tama is going to be booting from slot "A" only.

## Device

Device has to be unlockable. Check that before buying or be ready to return it if its impossible.

Update device to the last Android version before unlocking. You can update to Android 10 if offered and flash Sailfish 
over it directly. Check that all works before flashing Sailfish. If something doesn't work, it will be possible to claim 
the warranty on device.

If all is fine, check the consequences of bootloader unlocking as described by Sony and on relevant XDA forums.
Please note that unlocking makes some irreversible changes in device. If you agree with it, proceed with unlocking 
bootloader.

## Flashing files

You will need **USB2** connection between the phone and PC. If your PC comes only with UBS3, get a hub with USB2 
or flash on some other PC.

You will need reasonably new `fastboot` - it has to support `--disable-verity --disable-verification` options. You
could check that by running `fastboot --help`.

Files that will be needed for flashing:

- software binaries provided by Sony
- vbmeta image
- Sailfish release for your device

### Software binaries

For flashing, you will need software binaries (`SW_binaries_for_Xperia_Android_10.0.7.1_r1_v12a_tama.zip`). Get them from 
https://developer.sony.com/file/download/software-binaries-for-aosp-android-10-0-kernel-4-14-tama . Unzip the file, 
it would contain `SW_binaries_for_Xperia_Android_10.0.7.1_r1_v12a_tama.img`.

### vbmeta image

Get `vbmeta.zip` file from 4.1.0.24 release assets at
https://github.com/sailfishos-sony-tama/main/releases/download/4.1.0.24-aosp10-alpha1/vbmeta.zip
. Uncompress the file, it will contain single `vbmeta.img`

### Sailfish release

Get the latest Sailfish release ZIP file for your device among the releases at https://github.com/sailfishos-sony-tama/main/releases. Uncompress Sailfish ZIP and put the software binary and vbmeta images into the same folder.

### Flashing

Connect your device in fastboot mode. See Xperia 10 Sailfish X guide or guide for AOSP9 for your device, shortcuts are 
the same for Tama devices as for Xperia 10.

Ensure that your device is set to boot from slot "A". Use `fastboot getvar current-slot` to verify that. If it is
not, set it to boot from slot A by
```Shell
fastboot --set-active=a
fastboot reboot-bootloader
```
and check whether the slot is set correctly.

For flashing, use `flash.sh` or `flash-on-windows.bat`, accordingly. Again, follow Xperia 10 guide, but do not reboot
into Sailfish. **NB!** Flashing has been tested on Linux only. Please report on whether it worked on Windows under
corresponding [issue](https://github.com/sailfishos-sony-tama/main/issues/36).

When flashing the first time and unless you used `flash.sh` on Linux,
please flash also vbmeta.img (adjust for your PC OS):
```Shell
fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img
```
This command is included into Linux flash script `flash.sh` already and executed as a part of flashing script.

### Before booting into Sailfish

Unplug USB cable, and power on device after the led will turn itself off.
