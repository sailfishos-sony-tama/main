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

Until we get tama branch or unify it all under one with ganges, proceed as follows:

```
repo init -u git://github.com/mer-hybris/android.git -b sony-ganges-aosp-pie -m tagged-manifest.xml
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

Comment out a line below in $ANDROID_ROOT/.repo/manifest.xml
```
<project name="droid-src-sony-ganges-pie" path="rpm" 
```
using `<!-- ... !-->` notation.

Continue with syncing repo and build

```
repo sync -j8 --fetch-submodules
mv rpm droid-src
ln -s droid-src/patches .
droid-src/apply-patches.sh --mb
mv dhd-rpm rpm
./setup-sources.sh --mb

source build/envsetup.sh
export USE_CCACHE=1
lunch aosp_$DEVICE-user
make -j$(nproc --all) hybris-hal
```
