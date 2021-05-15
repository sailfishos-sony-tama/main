#!/bin/bash

set -e

# defaults
DEVICES="h8216 h8266 h8314 h8324 h8416 h9436"
ISMIC="no"
RELEASE=""

while :; do
    case $1 in
	--mic)
	    ISMIC=yes
	    ;;

	--release)
	    RELEASE=$2
	    shift
	    ;;

	--device)
	    DEVICES=$2
	    shift
	    ;;

	*)
	    break
    esac
    shift
done

EXTRA_NAME=

source ~/.hadk.env

# check if all is specified
[ -z "$RELEASE" ] && (echo "Release has to be specified with --release option" && exit -1)

URL=https://sailfishos-sony-tama.s3-website.pl-waw.scw.cloud/SailfishOS-$RELEASE-$PORT_ARCH

if [ "$ISMIC" == "no" ]; then
    scriptdir=`dirname "$(readlink -f "$0")"`
    RELEASE_DIR=$ANDROID_ROOT/releases/$RELEASE
    mkdir -p $RELEASE_DIR
    cd $RELEASE_DIR

    for device in $DEVICES
    do
	rm Jolla-@RELEASE@-$device-@ARCH@.ks || echo No old KS file, continuing
	"$scriptdir/get_ks.sh" $URL $device index.html
	sudo $PLATFORM_SDK_ROOT/sdks/sfossdk/mer-sdk-chroot \
	     "$scriptdir/create-images.sh" \
	     --mic \
	     --release $RELEASE --device $device
    done
    exit
fi

device=$DEVICES
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
