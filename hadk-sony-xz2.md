# HADK for Sony XZ2

This is based on
https://sailfishos.org/wiki/Sailfish_X_Xperia_Android_10_Build_and_Flash
and adjusted for Tama platform and, when needed, XZ2c device (apollo) of
this platform. As original port was based on Pie, some repositories
still have "pie" in their names.

## .hadk.env

```Shell
export DEVICE="h8324"
export HABUILD_DEVICE=apollo
export PLATFORM_SDK_ROOT="$HOME/mer"
export ANDROID_ROOT="$HOME/hadk"
export VENDOR="sony"
export FAMILY=tama
export ANDROID_VERSION_MAJOR=10
export HAVERSION="sony-aosp-"$ANDROID_VERSION_MAJOR

export PORT_ARCH="aarch64"

alias sfossdk=$PLATFORM_SDK_ROOT/sdks/sfossdk/mer-sdk-chroot

# required in Gentoo to link few libraries
# used by AOSP build
export LD_LIBRARY_PATH=~/aosp-lib
export PATH=~/aosp-lib/bin:$PATH
unset JAVAC
```

Content of

```
~/aosp-lib:
drwxr-xr-x bin
lrwxrwxrwx libncurses.so.5 -> /lib64/libncurses.so.6
lrwxrwxrwx libtinfo.so.5 -> /lib64/libtinfo.so.6

~/aosp-lib/bin:
total 0
lrwxrwxrwx 1 rinigus rinigus  7 Feb 20 11:21 python -> python3
lrwxrwxrwx 1 rinigus rinigus 18 Feb 20 11:21 python3 -> /usr/bin/python3.8
```

## Setting up sources

```Shell
HABUILD_SDK $

sudo apt-get install libssl-dev
sudo mkdir -p $ANDROID_ROOT
sudo chown -R $USER $ANDROID_ROOT
cd $ANDROID_ROOT
git clone -b hybris-10 --recurse-submodules https://github.com/sailfishos-sony-tama/droid-hal-sony-$FAMILY-pie .
```

In the HOST

```Shell
source ~/.hadk.env
cd $ANDROID_ROOT
repo init -u git://github.com/mer-hybris/android.git -b $HAVERSION -m tagged-localbuild.xml
# Adjust -j8 to bandwidth capabilities
repo sync -j8 --fetch-submodules
```


For patches, we use the same approach as official SFOS build instructions.
In the HOST:

```Shell
cd $ANDROID_ROOT

## if have to reset pulled sources
# repo sync -l

git clone --recurse-submodules https://github.com/mer-hybris/droid-src-sony droid-src
ln -s droid-src/patches
droid-src/apply-patches.sh --mb
./setup-sources.sh --mb
```


There are some patches that fix AOSP issues specific for Tama. Those
are distributed in this repository. To apply, clone this repository
somewhere outside $ANDROID_ROOT and apply them. Below, it is assumed
that this repository is available as `../main`:
```
cd $ANDROID_ROOT
ln -s ../main/patches patches-aosp
patches-aosp/apply-patches.sh --mb
```


# Build hybris-hal

Start the build, in HOST:

```Shell
cd $ANDROID_ROOT

# remove out to rebuild without additional android bits
# pulled by some services below (miniaudiopolicyservice)
rm -rf out

source build/envsetup.sh
export USE_CCACHE=1
lunch aosp_$DEVICE-user
cd kernel/sony/msm-4.14/common-kernel
./build-kernels-clang.sh -d $HABUILD_DEVICE -O $ANDROID_ROOT/out/target/product/$HABUILD_DEVICE/obj/kernel
# FIXME after this is merged: https://github.com/sonyxperiadev/kernel-sony-msm-4.14-common/pull/14
cp dtbo-$HABUILD_DEVICE.img $ANDROID_ROOT/out/target/product/$HABUILD_DEVICE/dtbo.img
cd -

# build hybris-hal only and package it to avoid mixing with other services
make -j$(nproc --all) hybris-hal
```


# Build systemimage vendorimage

This can be done in parallel to the previous or the next sections. On your Linux host:

```Shell
HOST $

source ~/.hadk.env

# on my system, there is additional config file that defines path with
# libncurses.so.5 and few other expected bits absent otherwise
source ~/.hadk.android

sudo mkdir -p $ANDROID_ROOT-syspart
sudo chown -R $USER $ANDROID_ROOT-syspart
cd $ANDROID_ROOT-syspart
# if you plan to contribute to syspart (/system partition), remove "--depth=1" and "-c" flags below
repo init -u git://github.com/mer-hybris/android.git -b $HAVERSION -m tagged-manifest.xml --depth=1
# Adjust -j8 to bandwidth capabilities
repo sync -j8 --fetch-submodules -c
ln -s rpm/patches .
rpm/apply-patches.sh --mb
```

There are some patches that fix AOSP issues specific for Tama. Those
are distributed in this repository. To apply, clone this repository
somewhere outside $ANDROID_ROOT and apply them. Below, it is assumed
that this repository is available as `../main`:
```
cd $ANDROID_ROOT-syspart
ln -s ../main/patches patches-aosp
patches-aosp/apply-patches.sh --mb
```

Build images (reduce `-j` as it is heavy on RAM if needed)

```Shell
source build/envsetup.sh
export USE_CCACHE=1
lunch aosp_$DEVICE-user
# vbmetaimage was missing in official SFOS instructions, is it needed?
make -j$(nproc --all) systemimage vendorimage vbmetaimage
```


# Setup SB2

Go through chapter 6 of the HADK document.


# Build HAL packages

In PLATFORM_SDK

```Shell
cd $ANDROID_ROOT

# check that packages are installed and env is OK
sudo zypper ref
sudo zypper in kmod pigz atruncate android-tools
sdk-foreach-su -ly ssu re

rpm/dhd/helpers/build_packages.sh --droid-hal
```

# syspart

After systemimage vendorimage have finished, in HOST
```Shell
mkdir -p $ANDROID_ROOT-tmp
sudo mkdir -p $ANDROID_ROOT-mnt-system
simg2img $ANDROID_ROOT-syspart/out/target/product/$HABUILD_DEVICE/system.img $ANDROID_ROOT-tmp/system.img.raw
sudo mount $ANDROID_ROOT-tmp/system.img.raw $ANDROID_ROOT-mnt-system

sudo mkdir -p $ANDROID_ROOT-mnt-vendor/vendor
simg2img $ANDROID_ROOT-syspart/out/target/product/$HABUILD_DEVICE/vendor.img $ANDROID_ROOT-tmp/vendor.img.raw
sudo mount $ANDROID_ROOT-tmp/vendor.img.raw $ANDROID_ROOT-mnt-vendor/vendor
# if fails:
# sudo losetup /dev/loop1 $ANDROID_ROOT-tmp/vendor.img.raw
# sudo mount /dev/loop1 $ANDROID_ROOT-mnt-vendor/vendor

# if cloned already, use
# cd $ANDROID_ROOT/hybris/mw/droid-system-sony-pie-template
cd $ANDROID_ROOT/hybris/mw
D=droid-system-$VENDOR-pie-template
git clone -b hybris-10 --recursive https://github.com/sailfishos-sony-tama/$D
cd $D

sudo droid-system-device/helpers/copy_tree.sh $ANDROID_ROOT-mnt-system/system $ANDROID_ROOT-mnt-vendor/vendor rpm/droid-system-$HABUILD_DEVICE.spec
# Note from official instructions, not sure if valid:
#    Please do not commit the binaries nor push them to a public repo,
#    because the license has not been determined,
#    thus they have to be built manually
sudo chown -R $USER .
sudo umount $ANDROID_ROOT-mnt-vendor/vendor
sudo umount $ANDROID_ROOT-mnt-system

# if losetup was used above:
# sudo losetup -d /dev/loop1
# sudo losetup -a

rm $ANDROID_ROOT-tmp/{system,vendor}.img.raw
sudo rm -rf $ANDROID_ROOT-mnt-{system,vendor}
rmdir $ANDROID_ROOT-tmp || true
```

If mount fails, try to use `losetup` to setup loop device and mount
from there.


# droidmedia and miniaudiopolicyservice

This should be done after HAL is packaged.

Android bits are needed as well. In HOST:

```
cd $ANDROID_ROOT

# pull external sources
git clone https://github.com/sailfishos/droidmedia external/droidmedia
git clone https://github.com/sailfishos-sony-tama/miniaudiopolicy.git hybris/mw/miniaudiopolicy

source build/envsetup.sh
export USE_CCACHE=1
lunch aosp_$DEVICE-user

make -j$(nproc --all) droidmedia miniaudiopolicyservice
```


In PLATFORM_SDK

```Shell
cd $ANDROID_ROOT

# droidmedia
DROIDMEDIA_VERSION=$(git --git-dir external/droidmedia/.git describe --tags | sed -r "s/\-/\+/g")
rpm/dhd/helpers/pack_source_droidmedia-localbuild.sh $DROIDMEDIA_VERSION
mkdir -p hybris/mw/droidmedia-localbuild/rpm
(cd hybris/mw/droidmedia-localbuild; git init; git commit --allow-empty -m "initial")
cp rpm/dhd/helpers/droidmedia-localbuild.spec hybris/mw/droidmedia-localbuild/rpm/droidmedia.spec
sed -ie "s/0.0.0/$DROIDMEDIA_VERSION/" hybris/mw/droidmedia-localbuild/rpm/droidmedia.spec
sed -ie "s/@PORT_ARCH@/$PORT_ARCH/" hybris/mw/droidmedia-localbuild/rpm/droidmedia.spec
sed -ie "s/@DEVICE@/$HABUILD_DEVICE/" hybris/mw/droidmedia-localbuild/rpm/droidmedia.spec
mv hybris/mw/droidmedia-$DROIDMEDIA_VERSION.tgz hybris/mw/droidmedia-localbuild
rpm/dhd/helpers/build_packages.sh --build=hybris/mw/droidmedia-localbuild

# miniaudiopolicy
hybris/mw/miniaudiopolicy/rpm/copy-hal.sh
rpm/dhd/helpers/build_packages.sh --build=hybris/mw/miniaudiopolicy --do-not-install
```

# Fingerprint support

Support is based on https://github.com/piggz/sailfish-fpd-community

In HABUILD_SDK

```Shell
HABUILD_SDK $
git clone https://github.com/piggz/sailfish-fpd-community.git hybris/mw/sailfish-fpd-community
source build/envsetup.sh
export USE_CCACHE=1
lunch aosp_$DEVICE-user (or appropriate name)
make libbiometry_fp_api
hybris/mw/sailfish-fpd-community/rpm/copy-hal.sh
```

In PLATFORM_SDK
```Shell
cd $ANDROID_ROOT
rpm/dhd/helpers/build_packages.sh --build=hybris/mw/sailfish-fpd-community --spec=rpm/droid-biometry-fp.spec --do-not-install

# this is needed only if building packages manually
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/piggz/sailfish-fpd-community-test.git --do-not-install
```


# System and Vendor

In PLATFORM_SDK
```Shell
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos-sony-tama/droid-system-sony-pie-template --do-not-install --spec=rpm/droid-system-$HABUILD_DEVICE.spec --spec=rpm/droid-system-$HABUILD_DEVICE-$DEVICE.spec
```

# Build packages and root system

Packages can be built using TBuilder or manually.

## Building using TBuilder

Get TBuilder and it's project repository:

In HOST
```Shell
cd ~
git clone https://github.com/rinigus/tbuilder
git clone --recursive https://github.com/sailfishos-sony-tama/tbuilder-project
```

In PLATFORM_SDK
```Shell
cd ~/tbuilder-project
sdk-assistant list

# choose target from the list above, such as SailfishOS-4.0.1.48-aarch64
# and give as argument to ./update-droid-hal.sh
./update-droid-hal.sh SailfishOS-4.0.1.48-aarch64
```

For up to date instructions on how to setup target, see
[README](https://github.com/sailfishos-sony-tama/tbuilder-project).

When target is ready, run build in PLATFORM_SDK
```Shell
# start build
../tbuilder/tbuilder .
```

when ready, publish the packages using `publish` script in TBuilder's project
repository by running in HOST
```Shell
./publish.sh
```

See script for requirements (have to have min.io mc available as
minmc as well as configured bucket).


## Root system

When using TBuilder and publishing the packages online, it is easy to
create root filesystem using a script from this (Main) repository. In
the folder with this HADK, run in your HOST
```Shell
scripts/create-images.sh --release 4.1.0.23 --device h8324
```

See [Building images
locally](https://github.com/sailfishos-sony-tama/main/blob/hybris-10/hadk-sony-xz2.md#building-images-locally)
for more info and how to build images for all supported devices.




## Building manually

### Configs

```Shell
cd $ANDROID_ROOT
git clone --recursive -b hybris-10 https://github.com/sailfishos-sony-tama/droid-config-sony-$FAMILY-pie hybris/droid-configs
rpm/dhd/helpers/build_packages.sh --configs
```


### Packages

In PLATFORM_SDK

```Shell
cd $ANDROID_ROOT
cd hybris/mw/libhybris
git checkout master
cd -
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/mer-hybris/sailfish-connman-plugin-suspend.git
rpm/dhd/helpers/build_packages.sh --mw # select "all" option when asked
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos/gst-droid.git
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos/gmp-droid.git
```

If getting error with bluez5:
```
sb2 -t $VENDOR-$DEVICE-$PORT_ARCH -R -msdk-install zypper in bluez5
```
and choose to change the provider.


### Other Tama specific packages

In HABUILD_SDK

```Shell
HABUILD_SDK $
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos-sony-tama/nemo-qml-plugin-systemsettings.git --do-not-install
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos-sony-tama/pkg-fsarchiver.git --do-not-install
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos-sony-tama/pickupd.git --do-not-install

## has to be fixed
#git clone -b pickup https://github.com/sailfishos-sony-tama/sensorfw.git hybris/mw/sensorfw
#rpm/dhd/helpers/build_packages.sh --build=hybris/mw/sensorfw --do-not-install

# updates for voice calls
rpm/dhd/helpers/build_packages.sh --mw=https://git.sailfishos.org/mer-core/ohm.git
rpm/dhd/helpers/build_packages.sh --mw=https://git.sailfishos.org/mer-core/libdres-ohm.git
rpm/dhd/helpers/build_packages.sh --mw=https://git.sailfishos.org/mer-core/ohm-plugins-misc.git

# required for cellular data
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/mer-hybris/dummy_netd.git --do-not-install

## updates from seine
#rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos/yamuisplash.git --do-not-install
```


### Boot packages

In PLATFORM_SDK

```Shell
cd $ANDROID_ROOT

rpm/dhd/helpers/build_bootimg_packages.sh
sb2 -t $VENDOR-$DEVICE-$PORT_ARCH -m sdk-install -R zypper in --force-resolution droid-hal-$HABUILD_DEVICE-kernel-modules

git clone -b hybris-10 --recursive https://github.com/sailfishos-sony-tama/droid-hal-img-boot-sony-$FAMILY-pie hybris/mw/droid-hal-img-boot-sony-$FAMILY-pie
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos-sony-tama/droid-hal-img-boot-sony-$FAMILY-pie --do-not-install --spec=rpm/droid-hal-$HABUILD_DEVICE-img-boot.spec

git clone --recursive https://github.com/sailfishos-sony-tama/droid-hal-img-dtbo-sony-$FAMILY-pie hybris/mw/droid-hal-img-dtbo-sony-$FAMILY-pie
cp out/target/product/$HABUILD_DEVICE/dtbo.img hybris/mw/droid-hal-img-dtbo-sony-tama-pie/dtbo-$HABUILD_DEVICE.img
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos-sony-tama/droid-hal-img-dtbo-sony-$FAMILY-pie --do-not-install --spec=rpm/droid-hal-$HABUILD_DEVICE-img-dtbo.spec

git clone --recursive https://github.com/sailfishos-sony-tama/droid-hal-version-sony-$FAMILY hybris/droid-hal-version-$DEVICE
```

Prepare config and version packages:

```Shell
cd $ANDROID_ROOT
# "rpm/dhd/helpers/build_packages.sh --configs" does not build jolla-configuration-*, but we need it.
# We cannot use just build jolla-configuration-$DEVICE.spec because that would cause the previously built
# droid-config-* rpms to be deleted, as they belong to the same hybris/droid-configs folder
# (this is an implementation choice in build_packages.sh and util.sh)
# In order to ensure both --configs rpms and jolla-configuration-* rpm are available, we need to build
# them using a single command.
rpm/dhd/helpers/build_packages.sh -b hybris/droid-configs --do-not-install --spec=rpm/droid-config-$DEVICE.spec --spec=rpm/patterns-sailfish-device-configuration-$DEVICE.spec

rpm/dhd/helpers/build_packages.sh --version
```


### Root filesystem

After manual building of packages, proceed with generation of root
filesystem.

In PLATFORM_SDK, start as in Chapter 8

KS has to be pulled from corresponding RPM:
```
rpm2cpio droid-local-repo/h8324/droid-configs/droid-config-*-ssu-kickstarts-*.rpm | cpio -idmv
```
If needed to edit, do it manually to set correct repositories. For local build, set
```
repo --name=adaptation-community-common-@DEVICE@-@RELEASE@ --baseurl=file:///home/rinigus/hadk/droid-local-repo/@DEVICE@
```
in KS under `usr/share/kickstarts`.

Run mic command
```
RELEASE=4.0.1.48
EXTRA_NAME=-my1
sudo zypper in lvm2 atruncate pigz
sudo zypper in android-tools
cd $ANDROID_ROOT
# no need to process patterns
sudo mic create loop --arch=$PORT_ARCH \
  --tokenmap=DEVICE:$DEVICE,ARCH:$PORT_ARCH,RELEASE:$RELEASE,EXTRA_NAME:$EXTRA_NAME,DEVICEMODEL:$DEVICE \
  --record-pkgs=name,url     --outdir=sfe-$DEVICE-$RELEASE$EXTRA_NAME \
  ./usr/share/kickstarts/Jolla-@RELEASE@-$DEVICE-@ARCH@.ks
```

**Troubleshooting missing package dependencies**

SailfishOS/Mer packages are often updated, this README is not.

If you are getting errors during the mic image build due to unsatisfied dependencies, try updating the RELEASE environment variable to the latest released version of SailfishOS.

# Port notes

## mixer_paths.xml

Mixer settings are the same for all Tama devices and are obtained by
reverting

- apollo: https://github.com/sonyxperiadev/device-sony-apollo/commit/ee4982625e2720669eb3e513f9cb4f02618b8df9
- akari: https://github.com/sonyxperiadev/device-sony-akari/commit/d12f2f4453fd296e33c60462ede4bed76ad8eb15
- akatsuki: https://github.com/sonyxperiadev/device-sony-akatsuki/commit/1313e299cd5c60a54f274354866b2a6a2da8c241

in the working tree. See issues

- https://github.com/sailfishos-sony-tama/main/issues/125
- https://github.com/sonyxperiadev/bug_tracker/issues/688

Currently this reverting is done via patches distributed in this
repository.

Regenerate system and vendor when the better solution is available.


# Updates

To update between versions, you would need to update SDK. For that, remove currently installed components (`sdk-assistant list`
will give the list) and use [update-sdk.sh](scripts/update-sdk.sh) for getting the new versions (modify the script accordingly).

If whole SDK is updated, don't forget to install the missing packages:
```
sudo zypper in kmod pigz atruncate android-tools
```

Make sure that when you run `mic` command, it will end up without errors. Otherwise, LVM

# Kernel or hybris HAL update

While we are on kernel 4.14, we follow kernel updates by Mer Hybris mainly. Kernel 4.14
is in Sony branch
[LA.UM.7.1.r1](https://github.com/sonyxperiadev/kernel/tree/aosp/LA.UM.7.1.r1)
and Mer Hybris branch
[hybris-sony-aosp/LA.UM.7.1.r1](https://github.com/mer-hybris/android_kernel_sony_msm/tree/hybris-sony-aosp/LA.UM.7.1.r1). To
compare our current kernel with others, use the links below:

* Commits missing from [Sony](https://github.com/sailfishos-sony-tama/android_kernel_sony_msm/compare/hybris-10.0-4.14...sonyxperiadev:aosp/LA.UM.7.1.r1)
* Commits missing from [Mer Hybris](https://github.com/sailfishos-sony-tama/android_kernel_sony_msm/compare/hybris-10.0-4.14...mer-hybris:hybris-sony-aosp/LA.UM.7.1.r1)
* Extra commits that we have when compared to [Sony](https://github.com/sonyxperiadev/kernel/compare/aosp/LA.UM.7.1.r1...sailfishos-sony-tama:hybris-10.0-4.14)
* Extra commits that we have when compared to [Mer Hybris](https://github.com/mer-hybris/android_kernel_sony_msm/compare/hybris-sony-aosp/LA.UM.7.1.r1...sailfishos-sony-tama:hybris-10.0-4.14)

For the updates, in HABUILD_SDK, see "Build hybris-hal" and "Build HAL
and config packages" above. Note that config packages are built
separately using TBuilder.

This will create packages in `droid-hal-DEVICE` and
`droid-hal-img-dtbo-sony-tama-pie` at `droid-local-repo`. Those can
copied to TBuidler project using update script in the project
repository.

This has to be repeated for all representative devices: h8216, h8314,
and h8416.


# Fastboot

To work with fastboot, we have to take into account bootloader
issues. So, to enter recovery or boot:

* boot into fastboot mode by holding volume up while connecting
  USB. LED should be blue when booted in fastboot mode.

* check for availibility of device by `fastboot -l devices`. Its easy
  to adjust permissions by making udev rules file allowing regular
  users to flash using fastboot. File /etc/udev/rules.d/51-android.rules:
  ```
  # Android devices
  SUBSYSTEM=="usb", ATTR{idVendor}=="0fce", MODE="0666", GROUP="plugdev"
  ```
  Here, `0fce` is obtained from `lsusb`.

* in PC, after detection of fastboot device (),
  reboot once in fastboot back to the bootloader : `fastboot reboot
  bootloader`

* to get into recovery, boot into it using `fastboot boot
  hybris-recovery.img `. Booting into recovery takes some time. Screen
  will show first unlocked bootloader warning, then will go blank, and
  later will boot. Should be up in a minute.

* When in recovery, `dmesg` on PC should show availibility of new
  ethernet device. Configure the device as in `ifconfig enp0s29f7u5
  10.42.66.65 netmask 255.255.255.0` .

* To login into recovery, use `telnet 10.42.66.66`


# Building images locally

Starting with 3.4.0.24, images are built using [create-images](scripts/create-images.sh)
script. It requires device-specific `.hadk.pre-DEVNAME` and generic `.hadk.post` environment
initialization files. To generate images for all devices, run `create-images.sh` after
adjusting RELEASE variable in the script. Images will be generated under
`$ANDROID_ROOT/releases/$RELEASE`.

Images can be uploaded using [release-image-uploader](scripts/release-image-uploader.sh)
script. You would need to have [github-release](https://github.com/github-release/github-release)
installed and security token enabled (see instructions at github-release, security token needs access
to public_repo). Also, adjust
repository and user name in the script.
