# OTA update instructions

It is recommended to perform OTA updates using SSH connection to the
phone from PC. It is possible that the phone display will refuse to
turn on after or during the update. By performing the update via SSH,
you can follow the progress and reboot the phone easily after it.

Note that OTA updates are supported via command line.

## Preparation for update

- Backup of Sailfish OS user files to a sdcard or to another device is
  strongly encouraged before updating Sailfish OS.

- Updates are tested by making updates between consecutive versions of
  Sailfish. Before skipping versions, check at
  [FSO](https://forum.sailfishos.org) whether it is recommended. In
  addition, read the [release
  notes](https://github.com/sailfishos-sony-tama/main/releases) for
  the versions that you plan to skip.

- Enable ability to change to root in Settings/Developer tools:
  - Enable 'Developer tools'
  - Set the password
  - Allow 'Remote connection' if you wish to update via ssh

- Open shell with normal defaultuser user preferrably via ssh

- Check that you have all expected repositories enabled using `ssu lr`. Example below when run from 4.6.0.13:
```
ssu lr
Enabled repositories (global):
 - adaptation-common                ... https://releases.jolla.com/releases/4.6.0.13/jolla-hw/adaptation-common/aarch64/
 - adaptation-community-tama-system ... https://repo.sailfishos.org/obs/nemo:/testing:/hw:/sony:/tama:/aosp10:/system/aosp10/
 - adaptation0                      ... https://repo.sailfishos.org/obs/nemo:/testing:/hw:/sony:/tama:/aosp10:/4.6.0.13/sailfishos_4.6.0.13_aarch64/
 - apps                             ... https://releases.jolla.com/jolla-apps/4.6.0.13/aarch64/
 - hotfixes                         ... https://releases.jolla.com/releases/4.6.0.13/hotfixes/aarch64/
 - jolla                            ... https://releases.jolla.com/releases/4.6.0.13/jolla/aarch64/

Enabled repositories (user):
 - sailfishos-chum  ... https://repo.sailfishos.org/obs/sailfishos:/chum/4.6.0.13_aarch64/
 - store            ... https://store-repository.jolla.com/h8216/aarch64/?version=4.6.0.13
```
Out of these repositories, make sure you have all repositories in `global` section and `store` in `user` section.
Also, check that they point to correct hosts, as shown above. With SFOS versions, URL would change, but changes
in hosts are not expected. In particular, `adaptation0` should point to `repo.sailfishos.org/...`. If pointing to Jolla's store or missing, download `community-adaptation-testing` package for your SFOS version from OBS. For example, for 4.5.0.24, from https://repo.sailfishos.org/obs/nemo:/testing:/hw:/sony:/tama:/aosp10:/4.5.0.24/sailfishos_4.5.0.24_aarch64/aarch64/ and install it using command line and zypper as in:
```bash
curl -O https://repo.sailfishos.org/obs/nemo:/testing:/hw:/sony:/tama:/aosp10:/4.5.0.24/sailfishos_4.5.0.24_aarch64/aarch64/community-adaptation-testing-1.2.0-1.1.1.jolla.aarch64.rpm
devel-su zypper in community-adaptation-testing-1.2.0-1.1.1.jolla.aarch64.rpm
```
While zypper may complain that the package is not signed, install it
anyway. After that, `ssu lr` should list the missing repository.

- After confirming that all repositories are there, check if you are up to date:
```bash
devel-su zypper ref
devel-su zypper up
```
If kernel or similar packages were installed, reboot before proceeding.

## Update repositories

- Point repositories to the new release
```bash
# Start with refresh of current SFOS repo
devel-su zypper ref
# Update all packages for current SFOS release
devel-su zypper up
# Replace DEVCODE below with your device code (see above). For XZ2 single sim - h8216
devel-su zypper in patterns-sailfish-device-configuration-DEVCODE

# Replace with the release you are updating to
ssu release 5.0.0.61

ssu lr
```

- At this stage, check that you have the port repos, as shown below (example for 5.0.0.61):
```
   - adaptation-common                ... https://releases.jolla.com/releases/5.0.0.61/jolla-hw/adaptation-common/aarch64/
   - adaptation-community-tama-system ... https://repo.sailfishos.org/obs/nemo:/testing:/hw:/sony:/tama:/aosp10:/system/aosp10/
   - adaptation0                      ... https://repo.sailfishos.org/obs/nemo:/testing:/hw:/sony:/tama:/aosp10:/5.0.0.61/sailfishos_5.0.0.61_aarch64/
```
As in the preparation stage above, it is important to make sure that adaptation0 points to https://repo.sailfishos.org host
and not Jolla's store. If your repos are missing adaptation0 or they point to Jolla's server, fix it by
installing the community adaptation package as root. Make sure you will get all repositories configured.

- You may have many of OpenRepos enabled. It's recommended to disable
 them, even though `version --dup` will do its best-effort to isolate
 repositories:
```
ssu lr | grep openrepos
```

## Update


- If you have all needed repositories, continue with the update:

```
devel-su zypper clean -a
devel-su zypper ref -f

devel-su version --dup
# if above fails, try again
# devel-su version --dup

# Check before reboot that all packages were installed
# Replace DEVCODE below with your device code (see above). For XZ2 single sim - h8216
devel-su zypper in patterns-sailfish-device-configuration-DEVCODE

# just in case
sync
```

- Reboot. If display does not turn on via power button and you don't
  have SSH connection, you would have to guess when the update is
  finished. Unfortunately, this guessing may lead to problems - hence
  SSH recommendation. However, to reboot in this case, you would have
  to press power button for a bit longer until red LED will turn on to
  indicate shutdown of SFOS. Release the power button and wait for the
  phone to shut down (red LED will turn off). Start it again by
  pressing power button.

- Note that on the first boot, it will reboot again automatically if the kernel is updated.
