#!/bin/bash

if [[ -z $1 ]]; then 
    echo "Usage: $0 INITRAMFS_DIR"
    exit 1
fi

cd $1
find . | cpio -H newc -o > ../initrd.cpio
cd ..
gzip initrd.cpio -c > initrd.gz

rm initrd.cpio
rm ../iso/initrd.gz
mv initrd.gz ../iso
