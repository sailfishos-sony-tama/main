# Generating droid-src patches

We use `generate_dhs_patches` to collect all changes made by Sony in their
repo_update script save them as patch files.

## Preperation

First you need to have a *plain* AOSP tree initialized with the version
matching to droid-hal e.g. in our case android-9.0.0-r46.

After that you need to delete the patches that were previously saved.
For that you need to look that you don't delete the patches made by us or Jolla.

## Generating the patches

After the cleanup is done its now time to generate the new patches.
For this you need to grab [generate_dhs_patches](https://github.com/mer-hybris/droid-hal-source/pull/7) and put it into the root of your android sources.

Now run:
```
droid_src_dir= # point it to your droid-src directory
./generate_dhs_patches.sh -m vendor \
    -r "$PWD/repo_update.sh" \
    -d $dhs_src_dir/patches
```

After that commit your changes and you are done.
