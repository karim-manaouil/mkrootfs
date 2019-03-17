#!/bin/bash

# Globals to control the build process 

HOSTNAME="esi"

BUILD_DIR="rootfs"

IMAGE="hdd.img"

USE_LOCAL_REPO="false"

LOCAL_REPO="http://localhost:8778/deian/amd64 /"

SYS_PACKAGES="linux-image-amd64, grub-pc, udev" 

BASE_PACKAGES="locales, adduser, vim, less, wget, passwd, sudo"

NET_PACKAGES="netbase, net-tools, iproute2, iputils-ping, isc-dhcp-client, ssh, network-manager"

GUI_PACKAGES=""

INCLUDE_PACKAGES=""

KEEP_DEBOOTSTRAP_DIR="true"

DEBOOTSTRAP_VERBOSE="true"

IMAGE_SIZE=0

ROOTFS_SIZE="" # Please, don't set this

LOOP_DEV=""

MOUNT_DIR="/tmp/mnt/"

GENERATE_VBOX_VDI="false"

##### build process #####

. core/stderr.sh

[ "$(id -u)" -ne 0 ] && fatal "${0##*\/} must be run as root(0)"

[ $# -ne 1 ] && fatal "rootfs dir is not specified !"

BUILD_DIR="$1"
BUILD_DIR=${BUILD_DIR%%/}

info "Starting build process"

for script in core/_*.sh; do
    [ ! -x "${script}" ] && chmod u+x "${script}";
    . "${script}";
done

include_packages SYS_PACKAGES BASE_PACKAGES NET_PACKAGES GUI_PACKAGES

if ! check_build_dir; then
    fatal "Build directory does not exist!"
fi

info "Preparing build dir"
if [ "$(ls -A ${BUILD_DIR} )" ]; then
	fatal "Build directory is not empty, removing its content is required!"
	#empty_build_dir  #we maybe need a confirmation input before applying this!
fi

if [[ "${USE_LOCAL_REPO}" == "true" ]]; then 
    spinup_local_repo;     
fi

debootstrap_rootfs

generate_system_image

create_partitions

copy_rootfs_sysimg

if [[ "${GENERATE_VBOX_VDI}" == "true" ]]; then
    info "Using VBoxManage to generate VDI image from RAW image ..."
    generate_vbox_vdi;
fi

finish_installation


