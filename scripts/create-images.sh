#!/bin/bash

set -e

# defaults
VERSION=testing
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

	--version)
	    VERSION=$2
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

case $VERSION in
    testing)
	URL=https://repo.sailfishos.org/obs/nemo:/testing:/hw:/sony:/tama:/aosp10:/${RELEASE}/sailfishos_${RELEASE}_${PORT_ARCH}/$PORT_ARCH/
	;;
    devel)
	URL=https://repo.sailfishos.org/obs/nemo:/devel:/hw:/sony:/tama:/aosp10/sailfish_latest_$PORT_ARCH/$PORT_ARCH/
	;;
    *)
	echo "Version (devel or testing) is not specified using --testing option"
	exit -2
	;;
esac

if [ "$ISMIC" == "no" ]; then
    scriptdir=`dirname "$(readlink -f "$0")"`
    RELEASE_DIR=$ANDROID_ROOT/releases/$RELEASE
    mkdir -p $RELEASE_DIR
    cd $RELEASE_DIR

    for device in $DEVICES
    do
	rm Jolla-@RELEASE@-$device-@ARCH@.ks || echo No old KS file, continuing
	"$scriptdir/get_ks.sh" $URL $device
	sudo $PLATFORM_SDK_ROOT/sdks/sfossdk/mer-sdk-chroot \
	     "$scriptdir/create-images.sh" \
	     --mic \
	     --release $RELEASE --version $VERSION --device $device
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
