# Sailfish OS port to Sony Xperia Tama devices

This is a community port, meaning that there is no official support and extensions included in the payed version:

* There is no Android app support
* There is no MS exchange support
* There is no payed predictive text support. Use Presage-based keyboards instead (see below)

Currently, only Xperia XZ2 single sim variant (H8216) is in the works.

**Current issues:** https://github.com/sailfishos-sony-tama/main/issues

Port is developed under https://github.com/sailfishos-sony-tama with the local and OBS builds supported. For setting
up local build, see [HADK](hadk-sony-xz2.md).

## Current state

The port is now on Sailfish 3.2.0.12. Its based on AOSP9 / Linux kernel 4.9.

For XZ2 H8216, working:

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
* USB Charging
* Sensors: light, proximity, gyroscope, acceloremeter
* Vibrator


## Flashing

Flashing guide is not ready. The images can be built using OBS repositories or compiled manually.

## Predictive text support

For predictive text support, install Presage-based predictive keyboards. These keyboards are available 
at OpenRepos, under [sailfish_keyboard applications](https://openrepos.net/user/12231/programs). After enabling OpenRepos,
you will need to enable that repository and install the keyboard layout(s) on your device. All the dependencies will be pulled 
during installation. For example, for English, install 
[English US Keyboard layout](https://openrepos.net/content/sailfishkeyboard/english-us-keyboard-layout-presage-based-text-prediction). 
