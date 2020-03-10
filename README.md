# Sailfish OS port to Sony Xperia Tama devices

Please read this document fully before planning or starting to use this port.

This is a community port, meaning that there is no official support and extensions included in the paid version:

* There is no Android app support
* There is no MS exchange support
* There is no Jolla Store predictive text support. Use Presage-based keyboards instead (see below)

The port is based on official port for Xperia 10. As a result, it has similar tools available for flashing
and the device userdata is partitioned using LVM.

As it requires unlocking bootloader on Sony Xperia, you will loose DRM keys and associated functionality. See
AOSP9 threads at XDA for your device for details. In particular, camera functionality will be considerably worse
than on stock Android by Sony, but should be similar to AOSP9.

While the care has been taken during porting, please see [LICENSE](LICENSE) for legal details.

## Issues 

Port issues are all reported within this repository: https://github.com/sailfishos-sony-tama/main/issues

## Supported devices

The following devices are supported:

* Xperia XZ2 single sim variant (H8216)
* Xperia XZ2 dual sim variant (H8266)
* Xperia XZ2 Compact single sim variant (H8314)
* Xperia XZ2 Compact dual sim variant (H8324)
* Xperia XZ3 single sim variant (H8416)
* Xperia XZ3 dual sim variant (H9436)

## Over-the-Air updates (OTA)

OTA updates are supported. Currently supported OTA updates are to the following releases:
- 3.2.1.20

OTA updates are supported via command line, as described below.
- Backup of Sailfish OS user files to a sdcard or to another device is strongly encouraged before updating Sailfish OS.
- You can be on any Sailfish OS version you have installed before.
- Enable ability to change to root in Settings/Developer tools:
  - Enable 'Developer tools'
  - Set the password
  - Allow 'Remote connection' if you wish to update via ssh
- Open shell with normal nemo user preferrably via ssh
- Updating Sailfish OS via commandline:
```bash
# Replace with the release you are updating to
ssu release 3.2.1.20

ssu lr
# Check the output that you have repos adaptation-community and adaptation-community-common

# You may have many of OpenRepos enabled. It's recommended to disable them, even
# though version --dup will do its best-effort to isolate repositories:
ssu lr | grep openrepos

devel-su zypper clean -a
devel-su zypper ref -f

version --dup
# if above fails, try again
# version --dup
sync
```
- Reboot

## Tips

* on one of the updates, run `rm ~/.cache/gstreamer-1.0/registry.*` to add hardware-supported H.265 decoding.


## Current state

Port is based on AOSP9 / Linux kernel 4.9.

Software stack state:

* Jolla Store access
* Kernel OTA update works
* OTA update for full OS not tested

Working hardware:

* Display
* Touch, multitouch
* LED
* Audio
* Bluetooth
* GPS
* WLAN (connect and hotspot)
* Camera (as in AOSP9)
* GSM (SMS, voice, data)
* Keys (Vol +/-, camera, power)
* Power management
* USB Charging, Network, MTP
* Sensors: light, proximity, gyroscope, acceloremeter
* Vibrator
* SD card
* NFC

## Flashing

Before flashing, please check the current [issues](https://github.com/sailfishos-sony-tama/main/issues) and 
pay attention to the [critical ones](https://github.com/sailfishos-sony-tama/main/issues?q=is%3Aopen+is%3Aissue+label%3Acritical). The critical issues may damage your hardware, so please
be aware of them.

Flashing guide is at [flashing.md](flashing.md).

## Predictive text support

For predictive text support, install Presage-based predictive keyboards. These keyboards are available 
at OpenRepos, under [sailfish_keyboard applications](https://openrepos.net/user/12231/programs). After enabling OpenRepos,
you will need to enable that repository and install the keyboard layout(s) on your device. All the dependencies will be pulled 
during installation. For example, for English, install 
[English US Keyboard layout](https://openrepos.net/content/sailfishkeyboard/english-us-keyboard-layout-presage-based-text-prediction). 

## Development

Port is developed under https://github.com/sailfishos-sony-tama with the local and OBS builds supported. For setting
up local build, see [HADK](hadk-sony-xz2.md).
