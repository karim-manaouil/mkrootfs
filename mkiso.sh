#!/bin/bash

output="debian.iso"

if [ ! -z "$1" ]; then
    output=$1
fi

if [ -e "$output" ]; then
    rm $output
fi

grub-mkrescue -o $output ./iso/

