#!/bin/bash

if [ -e "debian.iso" ]; then
    rm debian.iso
fi

grub-mkrescue -o debian.iso ./iso/

