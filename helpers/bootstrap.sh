#!/bin/bash

fatal() {
   >&2 echo $1
   exit 1
}

include_packages() {
    for suite in $@; do
        var="$suite";
        echo $suite="${!var}";
    done
}

choose_pkg_repo() {
    fatal "TODO"
}

check_build_dir() {
    if [ ! -d "${BUILD_DIR}" ]; then
        return 0
    fi

    return 1;
}

spinup_local_repo() {
    fatal "TODO"
}

debootstrap_rootfs() {
    fatal "TODO"
}

generate_system_image() {
    fatal "TODO"
}

copy_rootfs_sysimg() {
    fatal "TODO"
}

generate_vbox_vdi() {
    fatal "TODO"
}
