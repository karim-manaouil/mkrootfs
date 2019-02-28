#!/bin/bash

# This initrd is the live installation system

if [ $# -ne 2 ]
then
        echo "usage: mkinitramfs directory imagename.cpio.gz"
        exit 1
fi

if [ -d "$1" ]
then
    echo "creating $2 from $1"
    (cd "$1"; find . | cpio -o -H newc | gzip) > "$2"
else
    echo "First argument must be a directory"
    exit 1
fi
