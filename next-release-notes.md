# Notes for the next release

Use this file to prepare notes for the next release.

# Next release

## Update via OTA

Due to the changes introduced to support encryption of personal data, OTA is not possible from the earlier releases. You have to reflash the device.

## Images

Images are attached to this release. For `vbmeta.img`, use the same image as in [4.1.0.24 AOSP10 alpha](https://github.com/sailfishos-sony-tama/main/releases/tag/4.1.0.24-aosp10-alpha1).

## Changes

- Support for encryption based on [open source
  implementation](https://github.com/sailfishos-open/sailfish-device-encryption-community). When
  compared to the official implementation, the open source
  implementation allows greater flexibility in used encryption
  passwords, including hardware assisted solutions.

- Removal of factory reset images. Factory reset functionality
  required flashing the copy of the system to separate partition as
  well as inclusion of it into flashed ZIP. As a result of removing
  it, ZIP files reduced by the factor of 2 and users can, in
  principle, use the space for something else.

- Drop creation of log snapshots on boot and storing them in
  `/root`. If you need persistent logs, enable them using journal
  settings.

- ZGovernor adjusts GPU only (released as OTA already after 4.1.0.24
  AOSP10 beta).

