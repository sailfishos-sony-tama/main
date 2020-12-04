#!/bin/bash

set -e

RELEASE=3.4.0.24
EXTRA_NAME=

if [ "$#" -ne 1 ]; then
    scriptdir=`dirname "$(readlink -f "$0")"`
    RELEASE_DIR=$ANDROID_ROOT/releases/$RELEASE
    mkdir -p $RELEASE_DIR
    cd $RELEASE_DIR

    for device in h8216 h8266 h8314 h8324 h8416 h9436
    do
	rm Jolla-@RELEASE@-$device-@ARCH@.ks || echo No old KS file, continuing
	"$scriptdir/get_ks.sh" http://repo.merproject.org/obs/nemo:/testing:/hw:/sony:/tama/sailfishos_3.4.0.24/armv7hl/ $device
	sudo $PLATFORM_SDK_ROOT/sdks/sfossdk/mer-sdk-chroot "$scriptdir/create-images.sh" $device
    done
    exit
fi

device=$1
echo 
echo Building for $RELEASE $device

source ~/.hadk.pre-$device
source ~/.hadk.post

RELEASE_DIR=$ANDROID_ROOT/releases/$RELEASE
cd $RELEASE_DIR

sudo mic create loop --arch=$PORT_ARCH \
     --tokenmap=ARCH:$PORT_ARCH,RELEASE:$RELEASE,EXTRA_NAME:$EXTRA_NAME,DEVICEMODEL:$DEVICE \
     --record-pkgs=name,url --outdir=sfe-$DEVICE-$RELEASE$EXTRA_NAME \
     Jolla-@RELEASE@-$device-@ARCH@.ks
