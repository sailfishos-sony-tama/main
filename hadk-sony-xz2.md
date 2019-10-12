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
source build/envsetup.sh
export USE_CCACHE=1
lunch aosp_$DEVICE-user
make fec append2simg
make -j$(nproc --all) hybris-hal
```


# Build systemimage vendorimage

On your Linux host:

```
mkdir -p $ANDROID_ROOT-syspart
cd $ANDROID_ROOT-syspart
repo init -u git://github.com/sailfishos-sony-tama/android.git -b sony-aosp-pie -m tagged-manifest.xml --depth=1
mkdir .repo/local_manifests
```

Add the following content to $ANDROID_ROOT/.repo/local_manifests/$DEVICE.xml

```XML
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote fetch="https://github.com/sailfishos-sony-tama" name="hybris-tama"/>
  <project name="droid-src-sony-tama-pie" path="rpm" remote="hybris-tama" revision="master"/>
</manifest>
```

Setup the sources

```
repo sync -j8 --fetch-submodules -c
SKIP_SYNC=TRUE rpm/repo_update/repo_update.sh
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

Start the build (reduce `-j` as it is heavy on RAM if needed)

```
source build/envsetup.sh
export USE_CCACHE=1
lunch aosp_$DEVICE-user
make -j$(nproc --all) systemimage vendorimage
```
