# OTA from 4.1.0.24 Alpha to 4.1.0.24 Beta

As the hosting for the packages changed from TBuilder with
self-hosting to OBS with this release transition, OTA process is
somewhat different.

It is suggested to run these commands via SSH as it is easier to copy
and paste. As `root` on your phone, run

```Shell
zypper ref

# remove zgovernor as it is pulled later automatically
# this is to make sure that you will not run older version of it
zypper rm zgovernor

# update configs
zypper up
```

Check that you have repositories defined correctly:
```Shell
[root@XperiaXZ2 defaultuser]# ssu lr
Enabled repositories (global): 
 - adaptation-community-common      ... http://repo.merproject.org/obs/nemo:/testing:/hw:/common/sailfishos_4.1.0.24_aarch64/
 - adaptation-community-tama-system ... http://repo.merproject.org/obs/nemo:/testing:/hw:/sony:/tama:/aosp10:/system/aosp10/
 - adaptation0                      ... http://repo.merproject.org/obs/nemo:/testing:/hw:/sony:/tama:/aosp10/sailfishos_4.1.0.24_aarch64/
 - apps                             ... https://releases.jolla.com/jolla-apps/4.1.0.24/aarch64/
 - hotfixes                         ... https://releases.jolla.com/releases/4.1.0.24/hotfixes/aarch64/
 - jolla                            ... https://releases.jolla.com/releases/4.1.0.24/jolla/aarch64/

```

OpenRepos repositories will be listed as well, these are fine. Just
make sure that adaptation repositories are like listed above. If not,
try to figure out where the definitions come from. If they are not
under `/usr/share/ssu`, check `ssu` cache under `/var/cache/ssu/`. You
may have to delete them from the cache manually (see files in that
folder).

When all is fine, update repositories definitions and update
repositories by zypper:
```Shell
ssu ur
zypper ref
```
Note that zypper would have to refresh all new repositories.

Update the packages using distribution update:
```Shell
zypper dup
```

This will install zgovernor again (new packages), will update few,
downgrade several (just version number could be smaller), and will
change a vendor for DTBO package (droid-hal-*-img-dtbo).

After update, make a reboot.

As kernel is updated, the device will boot into SONY logo, finish the
update, and reboot again. After that it will boot into Sailfish fully.

This time, after boot into Sailfish GUI, you may not get touch working
immediately. Switch off screen using power button, switch it on with
the power button and touch should work.