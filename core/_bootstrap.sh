#!/bin/bash

include_packages() {
    local len=$#
    local len=$((len - 1));
    local args=("$@")

    for i in $(seq 0 $len); do
        if [ ! -z "${!args[$i]}" ]; then
            [ $i -eq 0 ] &&
                INCLUDE_PACKAGES="${!args[$i]}" ||            
                INCLUDE_PACKAGES="${INCLUDE_PACKAGES}, ${!args[$i]}"           
        fi
    done
}

choose_pkg_repo() {
    case $1 in
        local)
            PKG_REPO=$LOCAL_REPO
            ;;
        remote)
            PKG_REPO=$REMOTE_REPO
            ;;
        *)  
            fatal "Please specify either remote or local repo !"
            ;;
        esac
}

check_build_dir() {
    [ ! -d "${BUILD_DIR}" ] && false || true
}

empty_build_dir() {
    rm -rf "${BUILD_DIR}"/* 2>/dev/null 1>/dev/null
}

spinup_local_repo() {
    . makerepo.sh  
}

restore_apt_sources() {
    rm /etc/apt/sources.list
    mv /etc/apt/sources.xxdisthttpd.list \
        /etc/apt/sources.list
}

check_debootstrap_installation() {
    dpkg --get-selections | grep -q debootstrap
    local status=$?
    [ "${status}" -eq 0 ] && true || false
}

debootstrap_rootfs() {
    if ! check_debootstrap_installation; then
        fatal "debootstrap is not installed, please install it with 'sudo apt install debootstrap'"
    fi

    local opt=""
    local verbose=""

    if [[ "${KEEP_DEBOOTSTRAP_DIR}" == "true" ]]; then
        opt="--keep-debootstrap-dir";
    fi

    if [[ "${DEBOOTSTRAP_VERBOSE}" == "true" ]]; then 
        verbose="--verbose";
    fi
        
    local DEBOOTSTRAP_MIRROR=""

    if [[ "${USE_LOCAL_REPO}" == "true" ]]; then 
        DEBOOTSTRAP_MIRROR=$LOCAL_REPO;    
    fi

  echo  debootstrap "${verbose}" "${opt}" --components=main,contrib,non-free \
    --include="${INCLUDE_PACKAGES}" --exclude=nano \
    --arch amd64 stretch "${BUILD_DIR}" "${DEBOOTSTRAP_MIRROR}"

    [[ "$?" -ne 0 ]] && fatal "Cannot bootstrap rootfs !"
}

# Size is in megs
calc_rootfs_size() {
    local size=$(du -sh -BM "${BUILD_DIR}" | awk '{ print $1 }')    
    ROOTFS_SIZE="${size%%M}";
}

check_size_is_valid() {
    calc_rootfs_size
    [[ "${ROOTFS_SIZE}" -lt "${IMAGE_SIZE}" ]] && true || false
}

generate_system_image() {    
    if [[ "${IMAGE_SIZE}" -ne 0 ]]; then
        if ! check_size_is_valid; then
            fatal "Image size ${IMAGE_SIZE}M is not enough to contain the rootfs ${ROOTFS_SIZE}M"
        fi
        info "Image size verified";
    else
        info "Calculating image size ..."
        calc_rootfs_size
        IMAGE_SIZE="${ROOTFS_SIZE}"
    fi

    info "Image size is ${IMAGE_SIZE}M";
    info "Creating image ${IMAGE} ..."

    # Adding 4M of partition alignement + 10% metadata
    local megs=$((IMAGE_SIZE + IMAGE_SIZE/10 + 4))

    dd if=/dev/zero of="${IMAGE}" bs=$((1024*1024)) count="${megs}" 1>&2 2>/dev/null
}

check_loop_dev_is_created() {
    losetup --list | grep -q "${LOOP_DEV}"
}

create_partitions() {
    info "Creating system partition ..."
    LOOP_DEV=$(losetup --partscan --show --find "${IMAGE}")

    if ! check_loop_dev_is_created; then
        fatal "Image cannot be mounted as block device"
    fi

    (
        echo o  # DOS table
        echo n  # New part 
        echo p  # Primary
        echo 1  
        echo    # Default start (2048)
        echo    # Default end
        echo w 
    ) | fdisk "${LOOP_DEV}" >/dev/null 

    local fs="${LOOP_DEV}p1"

    info "Formatting ${fs} with ext4 ..."
    # ext4 part
    mkfs.ext4 "${fs}" 1>/dev/null 2>/dev/null

    [[ "$?" -ne 0 ]] && fatal "Cannot format partition !"

    info "Mounting rootfs ${fs} at ${MOUNT_DIR}"

    [[ ! -d "${MOUNT_DIR}" ]] && mkdir "${MOUNT_DIR}"
    mount -t ext4 "${fs}" "${MOUNT_DIR}" 1>/dev/null 2>/dev/null
    
    [[ "$?" -ne 0 ]] && fatal "Cannot mount partition !"

}

copy_rootfs_sysimg() {
    if [ ! -d "${MOUNT_DIR}" ]; then
        fatal "System partition is not mounted !";
    fi

    info "Copying root filesystem to system partition ..."
    cp -a "${BUILD_DIR}"/* "${MOUNT_DIR}"

    [[ "$?" -ne 0 ]] && fatal "Aborting. Error while copying !"

    info "Installing the grub bootloader ..."

    mount -B /proc "${MOUNT_DIR}proc"
    mount -B /sys "${MOUNT_DIR}sys"
    mount -B /dev "${MOUNT_DIR}dev"

    LC_ALL=C  chroot "${MOUNT_DIR}" grub-install --modules=part_msdos "${LOOP_DEV}" >/dev/null 2>&1
    LC_ALL=C  chroot "${MOUNT_DIR}" grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1

    [[ "$?" -ne 0 ]] && fatal "Could not install grub2 !"
}

generate_vbox_vdi() {
    VBoxManage convertdd "${IMAGE}" "${IMAGE%%.*}.vdi"
}

finish_installation() {
    if [[ "${USE_LOCAL_REPO}" == "true" ]]; then
        restore_apt_sources;
    fi

    umount "${MOUNT_DIR}/proc"
    umount "${MOUNT_DIR}/sys"
    umount "${MOUNT_DIR}/dev"
    umount "${MOUNT_DIR}"
    losetup -d "${LOOP_DEV}"
    rmdir "${MOUNT_DIR}"
    info "Generation process has finished. You can now burn your image or boot with qemu."
}
