#!/bin/bash

set -e

url=$1
rpm=droid-config-$2-ssu-kickstarts
dir=`dirname "$0"`
dir=`readlink -f "$dir"`

echo Downloading from: $url
echo RPM prefix: $rpm

rm -rf .get_ks || true
mkdir .get_ks && cd .get_ks
python3 $dir/download_ks.py $url $rpm

rpm2cpio droid-config-*-ssu-kickstarts-*.rpm | cpio -idmv
mv usr/share/kickstarts/Jolla-@RELEASE@-*-@ARCH@.ks ..
