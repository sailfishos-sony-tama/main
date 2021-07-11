#!/bin/bash

# script for updating droid-hal-* and similar packages

set -e

if [ -z "$ANDROID_ROOT" ]
then
    echo "ANDROID_ROOT variable is not defined in the shell"
    exit 1
fi

if [ ! -d system ]
then
    echo "Run from OBS system repo - directory system does not exist"
    exit 1
fi

# main device from which common packages are synced
main_device=h8324

rm system/*.rpm || true

# helper functions
sync_type() {
    local fam=$1
    local device=$2
    for files in \
	    droid-system-sony-pie-template/droid-system
    do
	rsync -av $ANDROID_ROOT/droid-local-repo/$device/${files}* system/
    done
}

sync_dev() {
    local fam=$1
    local device=$2
    for files in \
	    droid-system-sony-pie-template/droid-system-$fam-$device
    do
	rsync -av $ANDROID_ROOT/droid-local-repo/$device/${files}* system/
    done
}

### main ###

# sync device-specific
sync_type apollo h8324
sync_dev apollo h8314
sync_dev apollo h8324

sync_type akari h8216
sync_dev akari h8216
sync_dev akari h8266

sync_type akatsuki h8416
sync_dev akatsuki h8416
sync_dev akatsuki h9436
