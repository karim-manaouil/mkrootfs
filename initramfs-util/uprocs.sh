#!/bin/bash

expand_busybox()
{
    local busypath=""$BUILDROOT"bin/busybox"

    [[ ! -e $busypath ]] && return 1

    pushd ${busypath%busybox} 1>/dev/null 2>&1

    for bin in $(busybox --list); do
        ln -s busybox "$bin" 
    done

    popd 1>/dev/null 2>&1
}
