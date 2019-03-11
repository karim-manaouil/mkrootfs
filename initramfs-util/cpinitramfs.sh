#!/bin/bash

_d_ramfsdir="${1:-initramfs}"

pushd $_d_ramfsdir
find . | cpio -H newc -o > ../initrd.cpio
popd 

gzip initrd.cpio -c > initrd.gz

rm initrd.cpio
rm ../iso/initrd.gz
mv initrd.gz ../iso
