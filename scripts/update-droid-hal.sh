#!/bin/bash

# script for updating droid-hal-* and similar packages

set -e

if [ -z "$ANDROID_ROOT" ]
then
    echo "ANDROID_ROOT variable is not defined in the shell"
    exit 1
fi

if [ ! -d droid-hal-tama ]
then
    echo "Run from OBS repo - directory droid-hal-tama does not exist"
    exit 1
fi

# main device from which common packages are synced
main_device=h8324

rm droid-hal-tama/*.rpm || true

# helper functions
sync_type() {
    local fam=$1
    local device=$2
    for files in \
	droid-hal-h*/droid-hal \
	    droid-hal-img-dtbo*/
    do
	rsync -av $ANDROID_ROOT/droid-local-repo/$device/${files}* droid-hal-tama/
    done
}

### main ###

# sync device-specific
sync_type apollo h8324
#sync_dev apollo h8314
#sync_dev apollo h8324

sync_type akari h8216
#sync_dev akari h8216
#sync_dev akari h8266

sync_type akatsuki h8416
#sync_dev akatsuki h8416
#sync_dev akatsuki h9436

for files in \
    miniaudiopolicy/miniaudiopolicy \
    droidmedia-localbuild/droidmedia \
    sailfish-fpd-community/droid-biometry-fp
do
    rsync -av $ANDROID_ROOT/droid-local-repo/$main_device/${files}* droid-hal-tama/
done

# droid fake crypt needed by akatsuki
for files in \
    sailfish-fpd-community/droid-fake-crypt
do
    rsync -av $ANDROID_ROOT/droid-local-repo/h8416/${files}* droid-hal-tama/
done
