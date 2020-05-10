# HADK for Sony XZ2

This is based on https://sailfishos.org/wiki/Sailfish_X_Xperia_Android_9_Build_and_Flash and adjusted for Tama
platform and, when needed, XZ2 device (akari) of this platform.

## .hadk.env

```
export VENDOR="sony"
export DEVICE="h8216"
export HABUILD_DEVICE=akari
export FAMILY=tama
export ANDROID_FLAVOUR=pie
export HAVERSION="sony-"$FAMILY"-aosp-"$ANDROID_FLAVOUR
# Set arch to armv7hl even if you are porting a 64bit device
export PORT_ARCH="armv7hl"
```

## Setting up sources

```
HABUILD_SDK $

sudo apt-get install libssl-dev
sudo mkdir -p $ANDROID_ROOT
sudo chown -R $USER $ANDROID_ROOT
cd $ANDROID_ROOT
git clone https://github.com/sailfishos-sony-tama/droid-hal-sony-$FAMILY-$ANDROID_FLAVOUR .
git submodule init
git submodule update
cd hybris/mw/libhybris
git submodule init
git submodule update
cd -
ln -s ../dhd rpm/
mv rpm dhd-rpm
```

In contrast to official instructions, we use generic Sony AOSP repo and associate it with the device
via local manifest:

```
repo init -u git://github.com/sailfishos-sony-tama/android.git -b sony-aosp-pie -m tagged-manifest.xml
mkdir $ANDROID_ROOT/.repo/local_manifests
```

Add the following content to $ANDROID_ROOT/.repo/local_manifests/$DEVICE.xml

```XML
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote fetch="https://github.com/sailfishos-sony-tama" name="hybris-tama"/>
  <project name="droid-src-sony-tama-pie" path="rpm" remote="hybris-tama" revision="master"/>
</manifest>
```

Continue with syncing repo and build

```
repo sync -j8 --fetch-submodules
mv rpm droid-src
```

For patches, we use a mix of Sony's repo_update and hybris patches. This allows to simplify changes
in Android's base by keeping Sony's patches in sync with Android tree and apply all patches developed
for Hybris.

```
ln -s droid-src/patches .
droid-src/apply-patches.sh --mb
SKIP_SYNC=TRUE droid-src/repo_update/repo_update.sh
mv dhd-rpm rpm
./setup-sources.sh --mb
```

# Build hybris-hal

Start the build. As two targets are missed, we make them separately before main build

```
cd $ANDROID_ROOT
source build/envsetup.sh
export USE_CCACHE=1
lunch aosp_$DEVICE-user
make fec append2simg
make -j$(nproc --all) hybris-hal
make verity_key mkdtimg
mkdir -p kernel/sony/msm-4.9/common-kernel
out/host/linux-x86/bin/mkdtimg create kernel/sony/msm-4.9/common-kernel/dtbo-$HABUILD_DEVICE.img `find out/target/product/$HABUILD_DEVICE  -name "*.dtbo"`
cp kernel/sony/msm-4.9/common-kernel/dtbo-$HABUILD_DEVICE.img out/target/product/$HABUILD_DEVICE/dtbo.img
avbtool add_hash_footer --image out/target/product/$HABUILD_DEVICE/dtbo.img --partition_size 8388608 --partition_name dtbo
```


# Build systemimage vendorimage

This can be done in parallel to the previous or the next sections. On your Linux host:

Follow Sony's instructions for AOSP9 builds to set up sources. Note that the same branch as used
for tagged manifest in hybris AOSP has to be used:

```
mkdir -p $ANDROID_ROOT-syspart
cd $ANDROID_ROOT-syspart
BRANCH=android-9.0.0_r46
repo init -u https://android.googlesource.com/platform/manifest -b $BRANCH
cd .repo
git clone https://github.com/sonyxperiadev/local_manifests
cd local_manifests
git checkout $BRANCH
```

Add sfos.xml with the following content

```XML
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote fetch="https://github.com/sailfishos-sony-tama" name="hybris-tama"/>
  <project name="droid-src-sony-tama-pie" path="rpm" remote="hybris-tama" revision="master"/>
</manifest>
```

Continue sync and apply required patches:

```
cd ../..
repo sync -j32
./repo_update.sh
ln -s rpm/patches .
rpm/apply-patches.sh --mb
```

On Gentoo (probably not needed on other systems):
```
unset JAVAC
# due to https://github.com/sonyxperiadev/bug_tracker/issues/136
cd prebuilts/misc/linux-x86/flex
rm flex-2.5.39
tar zxf flex-2.5.39.tar.gz
cd flex-2.5.39
./configure
make
mv flex ../
cd ../
rm -rf flex-2.5.39
mv flex flex-2.5.39
cd ../../../../
```

Build images (reduce `-j` as it is heavy on RAM if needed)

```
source build/envsetup.sh
export USE_CCACHE=1
lunch aosp_$DEVICE-user
make -j$(nproc --all) systemimage vendorimage vbmetaimage
```


# Setup SB2

Go through chapter 6 of the HADK document.


# Build packages

In PLATFORM_SDK

```
cd $ANDROID_ROOT
sudo zypper ref
rpm/dhd/helpers/build_packages.sh --droid-hal
git clone --recursive https://github.com/sailfishos-sony-tama/droid-config-sony-$FAMILY-$ANDROID_FLAVOUR hybris/droid-configs -b master
rpm/dhd/helpers/build_packages.sh --configs
cd hybris/mw/libhybris
git checkout master
cd -
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/mer-hybris/sailfish-connman-plugin-suspend.git
rpm/dhd/helpers/build_packages.sh --mw # select "all" option when asked
```

# syspart

After systemimage vendorimage have finished, in HABUILD_SDK
```
cd $ANDROID_ROOT-syspart
sudo mkdir -p $ANDROID_ROOT-mnt
export PATH=$ANDROID_ROOT-syspart/out/host/linux-x86/bin:$PATH
simg2img out/target/product/$HABUILD_DEVICE/system.img /tmp/system.img.raw
sudo mount /tmp/system.img.raw $ANDROID_ROOT-mnt
cd $ANDROID_ROOT/hybris/mw
D=droid-system-$VENDOR-$ANDROID_FLAVOUR-template
git clone --recursive https://github.com/sailfishos-sony-tama/$D
cd $D
sudo droid-system-device/helpers/copy_system.sh $ANDROID_ROOT-mnt/system rpm/droid-system-$HABUILD_DEVICE.spec
# please do not commit the binaries nor push them to github repo,
# because the licence has not been determined,
# thus they have to be built manually
sudo chown -R $USER .
sudo umount $ANDROID_ROOT-mnt
rm /tmp/system.img.raw
cd $ANDROID_ROOT-syspart
simg2img out/target/product/$HABUILD_DEVICE/vendor.img /tmp/vendor.img.raw
sudo mount /tmp/vendor.img.raw $ANDROID_ROOT-mnt
cd $ANDROID_ROOT/hybris/mw
D=droid-vendor-$VENDOR-$ANDROID_FLAVOUR-template
git clone --recursive https://github.com/sailfishos-sony-tama/$D
cd $D
sudo droid-system-device/helpers/copy_vendor.sh $ANDROID_ROOT-mnt rpm/droid-system-vendor-$HABUILD_DEVICE.spec
sudo chown -R $USER .
sudo umount $ANDROID_ROOT-mnt
rm /tmp/vendor.img.raw
```

# audioflingerglue and droidmedia

In HABUILD_SDK

```
HABUILD_SDK $

cd $ANDROID_ROOT
git clone https://github.com/mer-hybris/audioflingerglue external/audioflingerglue
git clone https://github.com/sailfishos/droidmedia external/droidmedia

source build/envsetup.sh
export USE_CCACHE=1
lunch aosp_$DEVICE-user
make -j$(nproc --all) $(external/droidmedia/detect_build_targets.sh $PORT_ARCH $(gettargetarch)) $(external/audioflingerglue/detect_build_targets.sh $PORT_ARCH $(gettargetarch))
```

In PLATFORM_SDK

```
cd $ANDROID_ROOT
DROIDMEDIA_VERSION=$(git --git-dir external/droidmedia/.git describe --tags | sed -r "s/\-/\+/g")
rpm/dhd/helpers/pack_source_droidmedia-localbuild.sh $DROIDMEDIA_VERSION
mkdir -p hybris/mw/droidmedia-localbuild/rpm
(cd hybris/mw/droidmedia-localbuild; git init; git commit --allow-empty -m "initial")
cp rpm/dhd/helpers/droidmedia-localbuild.spec hybris/mw/droidmedia-localbuild/rpm/droidmedia.spec
sed -ie "s/0.0.0/$DROIDMEDIA_VERSION/" hybris/mw/droidmedia-localbuild/rpm/droidmedia.spec
mv hybris/mw/droidmedia-$DROIDMEDIA_VERSION.tgz hybris/mw/droidmedia-localbuild
rpm/dhd/helpers/build_packages.sh --build=hybris/mw/droidmedia-localbuild
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos/gst-droid.git

AUDIOFLINGERGLUE_VERSION=$(git --git-dir external/audioflingerglue/.git describe --tags | sed -r "s/\-/\+/g")
rpm/dhd/helpers/pack_source_audioflingerglue-localbuild.sh $AUDIOFLINGERGLUE_VERSION
mkdir -p hybris/mw/audioflingerglue-localbuild/rpm
(cd hybris/mw/audioflingerglue-localbuild; git init; git commit --allow-empty -m "initial")
cp rpm/dhd/helpers/audioflingerglue-localbuild.spec hybris/mw/audioflingerglue-localbuild/rpm/audioflingerglue.spec
sed -ie "s/0.0.0/$AUDIOFLINGERGLUE_VERSION/" hybris/mw/audioflingerglue-localbuild/rpm/audioflingerglue.spec
mv hybris/mw/audioflingerglue-$AUDIOFLINGERGLUE_VERSION.tgz hybris/mw/audioflingerglue-localbuild
rpm/dhd/helpers/build_packages.sh --build=hybris/mw/audioflingerglue-localbuild
# is in conflict with current config
# rpm/dhd/helpers/build_packages.sh --mw=https://github.com/mer-hybris/pulseaudio-modules-droid-glue.git

rpm/dhd/helpers/build_packages.sh --mw=https://github.com/mer-hybris/audiosystem-passthrough
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/mer-hybris/pulseaudio-modules-droid-hidl.git

```

# Boot packages

In PLATFORM_SDK

```
cd $ANDROID_ROOT
rpm/dhd/helpers/build_bootimg_packages.sh
sb2 -t $VENDOR-$DEVICE-$PORT_ARCH -m sdk-install -R zypper in --force-resolution droid-hal-$HABUILD_DEVICE-kernel-modules
git clone --recursive https://github.com/sailfishos-sony-tama/droid-hal-img-boot-sony-$FAMILY-$ANDROID_FLAVOUR hybris/mw/droid-hal-img-boot-sony-$FAMILY-$ANDROID_FLAVOUR
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos-sony-tama/droid-hal-img-boot-sony-$FAMILY-$ANDROID_FLAVOUR --do-not-install --spec=rpm/droid-hal-$HABUILD_DEVICE-img-boot.spec
git clone --recursive https://github.com/sailfishos-sony-tama/droid-hal-img-dtbo-sony-$FAMILY-$ANDROID_FLAVOUR hybris/mw/droid-hal-img-dtbo-sony-$FAMILY-$ANDROID_FLAVOUR
cp out/target/product/$HABUILD_DEVICE/dtbo.img hybris/mw/droid-hal-img-dtbo-sony-tama-pie/dtbo-$HABUILD_DEVICE.img
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos-sony-tama/droid-hal-img-dtbo-sony-$FAMILY-$ANDROID_FLAVOUR --do-not-install --spec=rpm/droid-hal-$HABUILD_DEVICE-img-dtbo.spec

rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos-sony-tama/droid-system-sony-$ANDROID_FLAVOUR-template --do-not-install --spec=rpm/droid-system-$HABUILD_DEVICE.spec --spec=rpm/droid-system-$HABUILD_DEVICE-$DEVICE.spec
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos-sony-tama/droid-vendor-sony-$ANDROID_FLAVOUR-template --do-not-install --spec=rpm/droid-system-vendor-$HABUILD_DEVICE.spec --spec=rpm/droid-system-vendor-$HABUILD_DEVICE-$DEVICE.spec

git clone --recursive https://github.com/sailfishos-sony-tama/droid-hal-version-sony-$FAMILY hybris/droid-hal-version-$DEVICE
```

# Root filesystem

In PLATFORM_SDK, start as in Chapter 8

```
cd $ANDROID_ROOT
# "rpm/dhd/helpers/build_packages.sh --configs" does not build jolla-configuration-*, but we need it.
# We cannot use just build jolla-configuration-$DEVICE.spec because that would cause the previously built
# droid-config-* rpms to be deleted, as they belong to the same hybris/droid-configs folder
# (this is an implementation choice in build_packages.sh and util.sh)
# In order to ensure both --configs rpms and jolla-configuration-* rpm are available, we need to build
# them using a single command.
rpm/dhd/helpers/build_packages.sh -b hybris/droid-configs --do-not-install --spec=rpm/jolla-configuration-$DEVICE.spec --spec=rpm/droid-config-$DEVICE.spec

rpm/dhd/helpers/build_packages.sh --version
HA_REPO="repo --name=adaptation-community-common-$DEVICE-@RELEASE@"
HA_DEV="repo --name=adaptation-community-$DEVICE-@RELEASE@"
KS="Jolla-@RELEASE@-$DEVICE-@ARCH@.ks"
sed \
"/$HA_REPO/i$HA_DEV --baseurl=file:\/\/$ANDROID_ROOT\/droid-local-repo\/$DEVICE" \
$ANDROID_ROOT/hybris/droid-configs/installroot/usr/share/kickstarts/$KS \
> $KS
RELEASE=3.2.1.20
EXTRA_NAME=-my1
sudo zypper in lvm2 atruncate pigz
sudo zypper in android-tools
cd $ANDROID_ROOT
# no need to process patterns
sudo mic create loop --arch=$PORT_ARCH \
    --tokenmap=ARCH:$PORT_ARCH,RELEASE:$RELEASE,EXTRA_NAME:$EXTRA_NAME,DEVICEMODEL:$DEVICE \
    --record-pkgs=name,url     --outdir=sfe-$DEVICE-$RELEASE$EXTRA_NAME \
    $KS
```

**Troubleshooting missing package dependencies**

SailfishOS/Mer packages are often updated, this README is not.

If you are getting errors during the mic image build due to unsatisfied dependencies, try updating the RELEASE environment variable to the latest released version of SailfishOS.

# Kernel or hybris HAL update

While we are on kernel 4.9, we follow kernel updates by Sony at branch
[LE.UM.2.3.2.r1.4](https://github.com/sonyxperiadev/kernel/tree/aosp/LE.UM.2.3.2.r1.4)
and by Mer Hybris at branch
[hybris-sony-aosp-9.0.0_r37_20190620](https://github.com/mer-hybris/android_kernel_sony_msm/tree/hybris-sony-aosp-9.0.0_r37_20190620). To
compare our current kernel with others, use the links below:

* Commits missing from [Sony](https://github.com/sailfishos-sony-tama/android_kernel_sony_msm/compare/hybris-sony-aosp-9.0.0-4.9-tama-sony...sonyxperiadev:aosp/LE.UM.2.3.2.r1.4)
* Commits missing from [Mer Hybris](https://github.com/sailfishos-sony-tama/android_kernel_sony_msm/compare/hybris-sony-aosp-9.0.0-4.9-tama-sony...mer-hybris:hybris-sony-aosp-9.0.0_r37_20190620)
* Extra commits that we have when compared to [Sony](https://github.com/sonyxperiadev/kernel/compare/aosp/LE.UM.2.3.2.r1.4...sailfishos-sony-tama:hybris-sony-aosp-9.0.0-4.9-tama-sony)
* Extra commits that we have when compared to [Mer Hybris](https://github.com/mer-hybris/android_kernel_sony_msm/compare/hybris-sony-aosp-9.0.0_r37_20190620...sailfishos-sony-tama:hybris-sony-aosp-9.0.0-4.9-tama-sony)

For the updates, in HABUILD_SDK
```
cd $ANDROID_ROOT
source build/envsetup.sh
export USE_CCACHE=1
lunch aosp_$DEVICE-user
make fec append2simg && make -j$(nproc --all) hybris-hal && make verity_key mkdtimg
out/host/linux-x86/bin/mkdtimg create kernel/sony/msm-4.9/common-kernel/dtbo-$HABUILD_DEVICE.img `find out/target/product/$HABUILD_DEVICE  -name "*.dtbo"`
cp kernel/sony/msm-4.9/common-kernel/dtbo-$HABUILD_DEVICE.img out/target/product/$HABUILD_DEVICE/dtbo.img
avbtool add_hash_footer --image out/target/product/$HABUILD_DEVICE/dtbo.img --partition_size 8388608 --partition_name dtbo
```

In PLATFORM_SDK,
```
cd $ANDROID_ROOT
rpm/dhd/helpers/build_packages.sh --droid-hal
sb2 -t $VENDOR-$DEVICE-$PORT_ARCH -m sdk-install -R zypper in --force-resolution droid-hal-$HABUILD_DEVICE-kernel-modules
cp out/target/product/$HABUILD_DEVICE/dtbo.img hybris/mw/droid-hal-img-dtbo-sony-tama-pie/dtbo-$HABUILD_DEVICE.img
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos-sony-tama/droid-hal-img-dtbo-sony-$FAMILY-$ANDROID_FLAVOUR --do-not-install --spec=rpm/droid-hal-$HABUILD_DEVICE-img-dtbo.spec
```

This will create packages in `droid-hal-DEVICE` and `droid-hal-img-dtbo-sony-tama-pie` at `droid-local-repo`.
Copy these to `droid-hal-tama` of OBS.

This has to be repeated for all representative devices: h8216, h8314, and h8416. When ready, push changes to OBS.


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
