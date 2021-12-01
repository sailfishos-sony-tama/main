# OTA from 4.2.0.21 to 4.3.0.12

As the repository layout has changed with 4.3.0.12 release, OTA
process is somewhat different.

It is suggested to run these commands via SSH as it is easier to copy
and paste. As `root` on your phone, run

```Shell
zypper ref

# update packages and configs
zypper up

# reboot
reboot
```

As kernel could be updated, the device will boot into SONY logo,
finish the update, and reboot again. After that it will boot into
Sailfish fully.

Check that you have repositories defined correctly:
```
ssu lr
 Enabled repositories (global): 
 - adaptation-common                ... https://releases.jolla.com/releases/4.2.0.21/jolla-hw/adaptation-common/aarch64/
 - adaptation-community-common      ... https://repo.sailfishos.org/obs/nemo:/testing:/hw:/common/sailfishos_4.2.0.21_aarch64/
 - adaptation-community-tama-system ... https://repo.sailfishos.org/obs/nemo:/testing:/hw:/sony:/tama:/aosp10:/system/aosp10/
 - adaptation0                      ... https://repo.sailfishos.org/obs/nemo:/testing:/hw:/sony:/tama:/aosp10:/4.2.0.21/sailfishos_4.2.0.21_aarch64/
...
```

Jolla and OpenRepos repositories will be listed as well, these are
fine. Just make sure that adaptation repositories, and `adaptation0`,
in particular, are like listed above. If not, try to figure out where
the definitions come from. If they are not under `/usr/share/ssu`,
check `ssu` cache under `/var/cache/ssu/`. You may have to delete them
from the cache manually (see files in that folder).

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

Accept downgrade of the packages, if needed. After update, make a
reboot.

As kernel is updated, the device will boot into SONY logo, finish the
update, and reboot again. After that it will boot into Sailfish fully.

After these steps, proceed to the regular OTA instructions.
