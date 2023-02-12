# Sailfish OS port to Sony Xperia Tama devices, AOSP 10 based

Please read this document fully before planning or starting to use this port.

This is a community port, meaning that there is no official support and extensions included in the paid version:

* There is no Jolla provided Android app support. Android apps are supported through Waydroid (see below)
* There is no MS exchange support
* There is no Jolla Store predictive text support. Use Presage-based keyboards instead (see below)

It is the second port for Xperia Tama, this time on top of AOSP10. The
port is based on official port for Xperia 10II (seine) and earlier
AOSP 9 based port for Xperia Tama. As a result, it has similar tools
available for flashing and the device userdata is partitioned using
LVM.

As it requires unlocking bootloader on Sony Xperia, you will loose DRM
keys and associated functionality. See AOSP10 threads at XDA for your
device for details regarding hardware support.

Documentation and development of the port is in `hybris-10` branch of
the repositories.

While the care has been taken during porting, please see
[LICENSE](LICENSE) for legal details.

## Issues 

Port issues are all reported within this repository:
https://github.com/sailfishos-sony-tama/main/issues . Specific
AOSP10-base issues can be seen using a
[filter](https://github.com/sailfishos-sony-tama/main/issues?q=is%3Aissue+label%3Ahybris-10+is%3Aopen).

## Supported devices

The following devices are supported:

* Xperia XZ2 single sim variant (h8216)
* Xperia XZ2 dual sim variant (h8266)
* Xperia XZ2 Compact single sim variant (h8314)
* Xperia XZ2 Compact dual sim variant (h8324)
* Xperia XZ3 single sim variant (h8416)
* Xperia XZ3 dual sim variant (h9436)

## Transition from AOSP9-based Sailfish OS port

To switch from AOSP9-based Sailfish port, see separate
[documentation](switch-from-aosp9.md).

## Over-the-Air updates (OTA)

OTA updates are supported. They were tested without public releases.

Currently supported OTA updates are to the following releases:

- 4.4.0.72
- 4.4.0.58
- 4.3.0.15
- [4.3.0.12](ota-from-4.2.0.21.md) See separate instructions for this update
- 4.2.0.21
- [4.1.0.24 Alpha to Beta](ota-from-alpha.md) See separate instructions for this update

OTA updates are supported via command line, as described below.
- Backup of Sailfish OS user files to a sdcard or to another device is strongly encouraged before updating Sailfish OS.
- Updates are tested by making updates between consecutive versions of Sailfish. Before skipping versions,
  check at [TJC](https://together.jolla.com) whether it is recommended. In addition, read the
  [release notes](https://github.com/sailfishos-sony-tama/main/releases) for the versions that you plan to skip.
- Enable ability to change to root in Settings/Developer tools:
  - Enable 'Developer tools'
  - Set the password
  - Allow 'Remote connection' if you wish to update via ssh
- Open shell with normal nemo user preferrably via ssh
- Updating Sailfish OS via commandline:
```bash
# Start with refresh of current SFOS repo
devel-su zypper ref 
# Update all packages for current SFOS release
devel-su zypper up
# Replace DEVCODE below with your device code (see above). For XZ2 single sim - h8216
devel-su zypper in patterns-sailfish-device-configuration-DEVCODE

# Replace with the release you are updating to
ssu release 4.4.0.72

ssu lr
# Check the output that you have repos adaptation-community and adaptation-community-common

# You may have many of OpenRepos enabled. It's recommended to disable them, even
# though version --dup will do its best-effort to isolate repositories:
ssu lr | grep openrepos

devel-su zypper clean -a
devel-su zypper ref -f

devel-su version --dup
# if above fails, try again
# devel-su version --dup

# Check before reboot that all packages were installed
# Replace DEVCODE below with your device code (see above). For XZ2 single sim - h8216
devel-su zypper in patterns-sailfish-device-configuration-DEVCODE

# just in case
sync
```
- Reboot

## Current state

Port is based on AOSP10 / Linux kernel 4.14 / aarch64.

Software stack state:

* Jolla Store access
* Kernel and OS OTA updates
* Storage encryption

Working hardware:

* Display
* Touch, multitouch
* Calls
* Cellular network
* LED
* Audio
* Bluetooth
* GPS
* WLAN (connect and hotspot)
* Camera (as in AOSP10)
* GSM (SMS, voice, data)
* Keys (Vol +/-, camera, power)
* Power management
* USB Charging, Network, MTP
* Wireless Charging
* Fingerprint
* Sensors: light, proximity, gyroscope, acceloremeter
* Sensors: magnetometer, compass, step counter, pickup
* Vibrator
* SD card

Build is distrbuted via OBS.

## Flashing

Before flashing, please check the current [issues](https://github.com/sailfishos-sony-tama/main/issues) and 
pay attention to the [critical ones](https://github.com/sailfishos-sony-tama/main/issues?q=is%3Aopen+is%3Aissue+label%3Acritical). The critical issues may damage your hardware, so please
be aware of them.

Flashing guide is at [flashing.md](flashing.md).

## Tips

### Predictive text support

For predictive text support, install Presage-based predictive
keyboards. These keyboards are available at [Chum
repositories](https://github.com/sailfishos-chum/main). After enabling
Chum, install the keyboard layout(s) on your device. For example, for
English:
```
devel-su zypper in keyboard-presage-en_US
```

List of available keyboards:
```
zypper se keyboard-presage-
```

### Fingerprint support

Fingerprint is supported through community effort
[sailfish-fpd-community](https://github.com/piggz/sailfish-fpd-community). It is
incorporated into the images.

Fingerprints can be used for authentication if you enable in Settings,
under "Device lock", use of security code.

When adding fingerprints, it is recommended to use separate
application: "Fingerprints". If you add fingerprints
under Sailfish Settings, it may lead to device reboot
([issue](https://github.com/piggz/sailfish-fpd-community/issues/10)). In
the dedicated application, such issue was not encountered.

### Android apps

Running Android apps is supported via WayDroid. To use WayDroid, follow the guide in 
[SFOS Waydroid packaging](https://github.com/sailfishos-open/waydroid/blob/main/README.md). 
Note that starting from SFOS version 4.5 release of this port, Waydroid gbinder configuration 
is included with the rest of device configurations. So, **do not install** 
`waydroid-gbinder-config-hybris` package on your device.

### Tracker and SD Cards

To allow tracker to index files on SD Card, run

```
gsettings set org.freedesktop.Tracker.Miner.Files index-recursive-directories "['&DESKTOP', '&DOCUMENTS', '&DOWNLOAD', '&MUSIC', '&PICTURES', '&VIDEOS',  '/run/media/nemo']"
```

### Step counter

Step counter is enabled and requires user space programs. Currently,
the best available interaction is through
[stpcntrd](https://github.com/kimmoli/stpcntrd) which registers DBus
session interface. You can use "Visual D-Bus" app to navigate to
`com.kimmoli.stpcntrd` and through that app call the methods. To
install the daemon, use
```
pkcon install stpcntrd
```
The daemon is included in Xperia Tama repositories.

### Pickup gesture

Pickup gesture switches on the screen when you pickup the phone and
allows you to avoid pressing a power button. It may require relatively
faster movement, try with the different movement patterns if it does
not work. Note that sometimes the gesture is not registered, try to
switch on / off the screen to re-arm the sensor. In addition, there is
some delay between pickup and switching on the screen, but that seems
to be originating mostly from the sensor or sensor-sensorfwd
interaction.

Pickup gesture requires development branch of
[sensorfwd](https://git.sailfishos.org/rinigus/sensorfw/tree/pickup)
and [pickupd](https://github.com/sailfishos-sony-tama/pickupd). The
both are available in Xperia Tama repositories.

To enable pickup gesture, you need to just install `pickupd`:
```
pkcon install pickupd
```
To disable, uninstall the daemon. 

### Pressure

Pressure sensor is configured. To my knowledge, the only application
interfacing it is Messwerk from
https://build.merproject.org/project/show/home:mal:apps .

### Launcher icons appear too small

A workaround around is to install [launcher-combined-patch](https://coderus.openrepos.net/pm2/project/launcher-combined) with [patchmanager](https://openrepos.net/content/coderus/patchmanager-30) and increase the icon size.

First install either patchmanager by hand or via [Storeman](https://openrepos.net/content/osetr/storeman).

Then install the patch by opening the settings app -> patchmanger -> pull-menu -> web-catalogue.

After this go a page back, select launcher-combined and enable change icon size.

### Resetting storage

From 4.2.0.21, it is possible to encrypt the storage. If you wish to
switch between encrypted and non-encrypted storage, see instructions
at [Community edition of Sailfish Encryption](https://github.com/sailfishos-open/sailfish-device-encryption-community#reset-configuration).
Note that this will result in loss of the data stored currently on
device - make sure to have a backup.

### Extending storage

It is possible to use system partitions that are not used in Sailfish for storage. This is for advanced users and
corresponding [instructions](extending-storage.md) are given separately.

### Use of cryptsetup in recovery

It is possible to use `cryptsetup`, but only after making chroot into `/rootfs`:

```
# in recovery
chroot /rootfs
cryptsetup ...
```

### Backup and recovery

The port supports backup and recovery when device is booted from recovery boot image. This is for advanced users and is available from
Sailfish 3.4.0.24 release. See [instructions](backup-recovery.md) for details.

## Development

Port is developed under https://github.com/sailfishos-sony-tama, under
`hybris-10` branches of repositories. For setting up a build, see
[HADK](hadk-sony-xz2.md).
