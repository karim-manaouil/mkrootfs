#!/bin/bash

# Globals to control the build process 

HOSTNAME="esi"

BUILD_DIR="rootfs"

IMAGE="esi-debian.img"

USE_LOCAL_REPO="false"

LOCAL_REPO="http://localhost:8778/deian/"

REMOTE_REPO="http://deb.debian.org/debian"

PKG_REPO=""

SYS_PACKAGES="linux-image-amd64, udev" 

BASE_PACKAGES="locales, adduser, vim, less, wget, passwd, sudo"

NET_PACKAGES="netbase, net-tools, iproute2, iputils-ping, isc-dhcp-client, ssh, network-manager"

GUI_PACKAGES=""

INCLUDE_PACKAGES=""

KEEP_DEBOOTSTRAP_DIR="true"

DEBOOTSTRAP_VERBOSE="true"

IMAGE_SIZE=0

GENERATE_VBOX_VDI="false"

##### build process #####

. stderr.sh

[ "$(id -u)" -ne 0 ] && fatal "${0##*\/} must be run as root(0)"

info "Starting build process"

for script in helpers/*.sh; do
    [ ! -x "${script}" ] && chmod u+x "${script}";
    . "${script}";
done

include_packages SYS_PACKAGES BASE_PACKAGES NET_PACKAGES GUI_PACKAGES

if ! check_build_dir; then
    fatal "Build directory does not exist!"
fi

info "Preparing build dir"
#rm -rf "${BUILD_DIR}"/* 2>/dev/null 1>/dev/null

if [[ "${USE_LOCAL_REPO}" == "true" ]]; then 
    spinup_local_repo;    
    choose_pkg_repo local 
else
    choose_pkg_repo remote
fi

debootstrap_rootfs

generate_system_image

create_partitions

copy_rootfs_sysimg

if [[ "${GENERATE_VBOX_VDI}" == "true" ]]; then
    generate_vbox_vdi;
fi
