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

if [[ "${USE_LOCAL_REPO}" == "true" ]]; then 
    spinup_local_repo;    
    choose_pkg_repo local 
else
    choose_pkg_repo remote
fi

debootstrap_rootfs

generate_system_image

copy_rootfs_sysimg

if [[ "${GENERATE_VBOX_VDI}" == "true" ]]; then
    generate_vbox_vdi;
fi

#debootstrap --verbose --components=main,contrib,non-free --include=--exclude=nano --arch amd64 stretch ./rootfs 


#(
#echo o # Create a new empty DOS partition table
#echo n # Add a new partition
#echo p # Primary partition
#echo 1 # Partition number
#echo   # First sector (Accept default: 1)
#echo   # Last sector (Accept default: varies)
#echo w # Write changes
#) | sudo fdisk

