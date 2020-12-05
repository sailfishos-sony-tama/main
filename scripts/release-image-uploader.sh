#!/bin/bash

set -e

if [ "$#" -ne 2 ]; then
    echo Usage: $0 release_tag github_token
    echo
    echo GitHub token can be created under your Github Settings/Developer settings/Personal access tokens
    echo This uploader is using https://github.com/github-release/github-release
    exit
fi

tag=$1
token=$2

echo Uploading images to $tag

for d in sfe-*/Sailfish_OS-*.zip; do
    fname=`basename $d`
    echo Uploading $d as $fname
    github-release upload -s $token \
                   -u sailfishos-sony-tama -a rinigus -r main \
                   -t $tag \
                   -f $d -n $fname
done

