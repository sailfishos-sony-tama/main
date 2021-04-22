#!/bin/bash

set -e

MB=$1

USE_PATCH=1
if [ "$MB" == "--mb" ]; then
    USE_PATCH=0
fi

OLD_WD=`pwd`
cd patches-aosp

if [ "$USE_PATCH" == "1" ]; then
    for patch in `find . -name *.patch |sort`; do
        cd $OLD_WD/$(dirname $patch)
        patch -p1 < $OLD_WD/patches/$patch
    done
else
    MBS=$(find . -name *.patch -exec dirname {} \; |sort -u)
    for mb in $MBS; do
        cd $OLD_WD/$mb
        git am $OLD_WD/patches-aosp/$mb/*.patch
    done
fi

