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
# Adjust X to bandwidth capabilities
repo sync -jX --fetch-submodules
```


For patches, we use the same approach as official SFOS build instructions.
In the HOST:

```Shell
cd $ANDROID_ROOT
git clone --recurse-submodules https://github.com/mer-hybris/droid-src-sony droid-src
ln -s droid-src/patches
droid-src/apply-patches.sh --mb
./setup-sources.sh --mb
```

# Build hybris-hal

Start the build, in HOST:

```Shell
cd $ANDROID_ROOT
# wipe out folder before building again
rm -rf out

source build/envsetup.sh
export USE_CCACHE=1
lunch aosp_$DEVICE-user
cd kernel/sony/msm-4.14/common-kernel
./build-kernels-clang.sh -d $HABUILD_DEVICE -O $ANDROID_ROOT/out/target/product/$HABUILD_DEVICE/obj/kernel
# FIXME after this is merged: https://github.com/sonyxperiadev/kernel-sony-msm-4.14-common/pull/14
cp dtbo-$HABUILD_DEVICE.img $ANDROID_ROOT/out/target/product/$HABUILD_DEVICE/dtbo.img
cd -
make -j$(nproc --all) hybris-hal
```


# Build systemimage vendorimage

This can be done in parallel to the previous or the next sections. On your Linux host:

```Shell
HOST $

source ~/.hadk.env

sudo mkdir -p $ANDROID_ROOT-syspart
sudo chown -R $USER $ANDROID_ROOT-syspart
cd $ANDROID_ROOT-syspart
# if you plan to contribute to syspart (/system partition), remove "--depth=1" and "-c" flags below
repo init -u git://github.com/mer-hybris/android.git -b $HAVERSION -m tagged-manifest.xml --depth=1
# Adjust X to bandwidth capabilities
repo sync -jX --fetch-submodules -c
ln -s rpm/patches .
rpm/apply-patches.sh --mb
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


# Build HAL and config packages

In PLATFORM_SDK

```Shell
cd $ANDROID_ROOT
sudo zypper ref
rpm/dhd/helpers/build_packages.sh --droid-hal
git clone --recursive -b hybris-10 https://github.com/sailfishos-sony-tama/droid-config-sony-$FAMILY-pie hybris/droid-configs 
rpm/dhd/helpers/build_packages.sh --configs
```

# syspart

After systemimage vendorimage have finished, in HABUILD_SDK
```Shell
mkdir -p $ANDROID_ROOT-tmp
sudo mkdir -p $ANDROID_ROOT-mnt-system
simg2img $ANDROID_ROOT-syspart/out/target/product/$HABUILD_DEVICE/system.img $ANDROID_ROOT-tmp/system.img.raw
sudo mount $ANDROID_ROOT-tmp/system.img.raw $ANDROID_ROOT-mnt-system

sudo mkdir -p $ANDROID_ROOT-mnt-vendor/vendor
simg2img $ANDROID_ROOT-syspart/out/target/product/$HABUILD_DEVICE/vendor.img $ANDROID_ROOT-tmp/vendor.img.raw
sudo mount $ANDROID_ROOT-tmp/vendor.img.raw $ANDROID_ROOT-mnt-vendor/vendor

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
rm $ANDROID_ROOT-tmp/{system,vendor}.img.raw
sudo rm -rf $ANDROID_ROOT-mnt-{system,vendor}
rmdir $ANDROID_ROOT-tmp || true
```

# droidmedia

In HABUILD_SDK

```Shell
HABUILD_SDK $

cd $ANDROID_ROOT
git clone https://github.com/sailfishos/droidmedia external/droidmedia

source build/envsetup.sh
export USE_CCACHE=1
lunch aosp_$DEVICE-user
make -j$(nproc --all) droidmedia
```

In PLATFORM_SDK

```Shell
cd $ANDROID_ROOT
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
```

# Build packages

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

# Fingerprint support

NOT YET, AOSP10/aarch64?

Support is based on https://github.com/piggz/sailfish-fpd-community

In HABUILD_SDK

```Shell
HABUILD_SDK $
git clone https://github.com/piggz/sailfish-fpd-community.git hybris/mw/sailfish-fpd-community
source build/envsetup.sh
export USE_CCACHE=1
lunch aosp_$DEVICE-user (or appropriate name)
make libbiometry_fp_api_32
hybris/mw/sailfish-fpd-community/rpm/copy-hal.sh
```

In PLATFORM_SDK
```Shell
cd $ANDROID_ROOT
rpm/dhd/helpers/build_packages.sh --build=hybris/mw/sailfish-fpd-community --spec=rpm/droid-biometry-fp.spec --do-not-install
```


# Boot packages

In PLATFORM_SDK

```Shell
cd $ANDROID_ROOT
rpm/dhd/helpers/build_bootimg_packages.sh
sb2 -t $VENDOR-$DEVICE-$PORT_ARCH -m sdk-install -R zypper in --force-resolution droid-hal-$HABUILD_DEVICE-kernel-modules
git clone -b hybris-10 --recursive https://github.com/sailfishos-sony-tama/droid-hal-img-boot-sony-$FAMILY-pie hybris/mw/droid-hal-img-boot-sony-$FAMILY-pie
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos-sony-tama/droid-hal-img-boot-sony-$FAMILY-pie --do-not-install --spec=rpm/droid-hal-$HABUILD_DEVICE-img-boot.spec
git clone -b hybris-10 --recursive https://github.com/sailfishos-sony-tama/droid-hal-img-dtbo-sony-$FAMILY-pie hybris/mw/droid-hal-img-dtbo-sony-$FAMILY-pie
cp out/target/product/$HABUILD_DEVICE/dtbo.img hybris/mw/droid-hal-img-dtbo-sony-tama-pie/dtbo-$HABUILD_DEVICE.img
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos-sony-tama/droid-hal-img-dtbo-sony-$FAMILY-pie --do-not-install --spec=rpm/droid-hal-$HABUILD_DEVICE-img-dtbo.spec

rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos-sony-tama/droid-system-sony-pie-template --do-not-install --spec=rpm/droid-system-$HABUILD_DEVICE.spec --spec=rpm/droid-system-$HABUILD_DEVICE-$DEVICE.spec

git clone --recursive https://github.com/sailfishos-sony-tama/droid-hal-version-sony-$FAMILY hybris/droid-hal-version-$DEVICE
```

# Root filesystem

In PLATFORM_SDK, start as in Chapter 8

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

KS has to be pulled from corresponding RPM:
```
rpm2cpio droid-local-repo/h8324/droid-configs/droid-config-*-ssu-kickstarts-*.rpm | cpio -idmv
```
If needed to edit, do it manually. Keeping older approach for reference and mic command
```
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

# Updates

To update between versions, you would need to update SDK. For that, remove currently installed components (`sdk-assistant list`
will give the list) and use [update-sdk.sh](scripts/update-sdk.sh) for getting the new versions (modify the script accordingly).

If whole SDK is updated, don't forget to install the missing packages:
```
sudo zypper in kmod pigz atruncate android-tools
```

Make sure that when you run `mic` command, it will end up without errors. Otherwise, LVM 

# Kernel or hybris HAL update

While we are on kernel 4.9, we follow kernel updates by Mer Hybris mainly. Kernel 4.9 
is in Sony branch
[LE.UM.2.3.2.r1.4](https://github.com/sonyxperiadev/kernel/tree/aosp/LE.UM.2.3.2.r1.4)
and Mer Hybris branch
[hybris-sony-aosp-9.0.0_r37_20190620](https://github.com/mer-hybris/android_kernel_sony_msm/tree/hybris-sony-aosp-9.0.0_r37_20190620). To
compare our current kernel with others, use the links below:

* Commits missing from [Sony](https://github.com/sailfishos-sony-tama/android_kernel_sony_msm/compare/hybris-9.0-4.9...sonyxperiadev:aosp/LE.UM.2.3.2.r1.4)
* Commits missing from [Mer Hybris](https://github.com/sailfishos-sony-tama/android_kernel_sony_msm/compare/hybris-9.0-4.9...mer-hybris:hybris-sony-aosp-9.0.0_r37_20190620)
* Extra commits that we have when compared to [Sony](https://github.com/sonyxperiadev/kernel/compare/aosp/LE.UM.2.3.2.r1.4...sailfishos-sony-tama:hybris-9.0-4.9)
* Extra commits that we have when compared to [Mer Hybris](https://github.com/mer-hybris/android_kernel_sony_msm/compare/hybris-sony-aosp-9.0.0_r37_20190620...sailfishos-sony-tama:hybris-9.0-4.9)

For the updates, in HABUILD_SDK
```Shell
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
```Shell
cd $ANDROID_ROOT
rpm/dhd/helpers/build_packages.sh --droid-hal
sb2 -t $VENDOR-$DEVICE-$PORT_ARCH -m sdk-install -R zypper in --force-resolution droid-hal-$HABUILD_DEVICE-kernel-modules
cp out/target/product/$HABUILD_DEVICE/dtbo.img hybris/mw/droid-hal-img-dtbo-sony-tama-pie/dtbo-$HABUILD_DEVICE.img
rpm/dhd/helpers/build_packages.sh --mw=https://github.com/sailfishos-sony-tama/droid-hal-img-dtbo-sony-$FAMILY-pie --do-not-install --spec=rpm/droid-hal-$HABUILD_DEVICE-img-dtbo.spec
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


# Building on CI

When using Gitlab CI, we can set the type of the build (devel or
testing) through CI variables. Build images are pushed to
https://thaodan.de/public/sailfishos/community/images/sony/tama .

During SFOS update, variables REPO, TAMA_RELEASE, REPO_RELEASE have to
be changed. Variable REPO is used during a build, it can be filled
using values in other REPO_ vars.


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


# Update notes: 3.4.0.24

* As upstream has new meta packages configuration, the configuration used by Tama is combination of 
  the one developed for it and the official one. New PR was submitted, https://github.com/mer-hybris/droid-hal-configs/pull/203. 
  For now, local branch from https://github.com/sailfishos-sony-tama/droid-hal-configs is used.
  
* Switching over to kernel following mer-hybris Sony kernel version. As that kernel is
  updated, there is no reason to start merging changes from two sources (Sony and Mer), but
  it is sufficient to follow Mer which is following Sony updates by itself.

* We now use `generate_dhs_patches` instead of using sonys repo_update script.

* Vendor repositories are set to p-mr1 to don't changes incompatible
  with Android pie.

# Update notes: 3.3.0.16

* dhd (submodule of
  https://github.com/sailfishos-sony-tama/droid-hal-sony-tama-pie) was
  taken not from master but from `filesystem` branch to get access to
  https://github.com/mer-hybris/droid-hal-device/commit/d75a605795895988a0543385ba4aca6bf50c0db7
  . Without it, I was getting an error during kernel image
  installation (cpio: open failed - File exists). Hopefully, changes
  will be merged and we can switch back to master

* https://github.com/sailfishos-sony-tama/droid-hal-configs is
  composed to use meta packages. Thus, until
  https://github.com/mer-hybris/droid-hal-configs/pull/175 is merged,
  it has to be used instead of upstream. So, we currently use
  sfos-3.3.0.16 branch as a submodule in
  https://github.com/sailfishos-sony-tama/droid-config-sony-tama-pie.
