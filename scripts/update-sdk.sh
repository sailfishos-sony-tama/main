#!/bin/bash

set -e

SFOS=3.4.0.24

sdk-assistant create -y SailfishOS-$SFOS http://releases.sailfishos.org/sdk/targets/Sailfish_OS-$SFOS-Sailfish_SDK_Tooling-i486.tar.7z
for device in h8216 h8266 h8314 h8324 h8416 h9436
do
  sdk-assistant create -y sony-$device-armv7hl \
     http://releases.sailfishos.org/sdk/targets/Sailfish_OS-$SFOS-Sailfish_SDK_Target-armv7hl.tar.7z
done

sdk-assistant list

