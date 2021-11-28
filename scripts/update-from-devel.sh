#!/bin/bash

set -e

diff -q -x community-adaptation-testing -x community-adaptation-devel ../nemo:devel:hw:sony:tama:aosp10 ./ || (echo Difference in dirs, cannot continue && exit 1)

root=`pwd`

echo Syncing
for d in *; do
    if [ $d == community-adaptation-testing ]; then
	continue
    fi
    echo Updating $d
    cd $d
    rsync -av --delete --exclude .osc/ ../../nemo:devel:hw:sony:tama:aosp10/$d/ ./
    cd $root
done


