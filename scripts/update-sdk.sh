#!/bin/bash

set -e

SFOS=4.1.0.24

sdk-assistant create -y SailfishOS-$SFOS http://releases.sailfishos.org/sdk/targets/Sailfish_OS-$SFOS-Sailfish_SDK_Tooling-i486.tar.7z
curl -O http://releases.sailfishos.org/sdk/targets/Sailfish_OS-$SFOS-Sailfish_SDK_Target-$PORT_ARCH.tar.7z
for device in h8216 h8266 h8314 h8324 h8416 h9436
do
  sdk-assistant create -y sony-$device-$PORT_ARCH \
     Sailfish_OS-$SFOS-Sailfish_SDK_Target-$PORT_ARCH.tar.7z
done

sdk-assistant create -y SailfishOS-$SFOS-$PORT_ARCH \
	      Sailfish_OS-$SFOS-Sailfish_SDK_Target-$PORT_ARCH.tar.7z

sdk-assistant list
echo
sdk-foreach-su -ly ssu re
