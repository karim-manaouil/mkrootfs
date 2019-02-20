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

spinup_local_repo() {
    fatal "TODO"
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
        
echo    debootstrap "${verbose}" "${opt}" --components=main,contrib,non-free \
    --include="${INCLUDE_PACKAGES}" --exclude=nano \
    --arch amd64 stretch "${BUILD_DIR}"
}

# Size should be in megs otherwise this won't work
calc_rootfs_size() {
    local size=$(du -sh "${BUILD_DIR}" | awk '{ print $1 }')    
    return "${size%%M}";
}

check_size_is_valid() {
    calc_rootfs_size
    local size=$?
    [[ "${size}" -ge "${IMAGE_SIZE}" ]] && true || false
}

generate_system_image() {
    
    if [[ "${IMAGE_SIZE}" -ne 0 ]]; then
        if ! check_size_is_valid; then
            fatal "Image size is not enough to contain the rootfs"
        fi
        info "Image size verified";
    else
        info "Calculating image size"
        calc_rootfs_size
        IMAGE_SIZE=$?
    fi

    info "Image size is ${IMAGE_SIZE}M";
    info "Creating image ${IMAGE}"

    dd if=/dev/zero of="${IMAGE}" bs=$((1024*1024)) count="${IMAGE_SIZE}" 1>&2 2>/dev/null
   
    info "Image created successfully" 
}

create_partition() {
    info "Creating system partition ..."
    LOOP_DEV=$(losetup --partscan --show --find)
    (
        echo o  # DOS table
        echo n  # New part 
        echo p  # Primary
        echo 1  
        echo    # Default start (2048)
        echo    # Default end
        echo w 
    ) | fdisk "${LOOP_DEV}"

    info "Formatting with ext4 ..."
    # ext4 part
    mkfs.ext4 "${LOOP_DEV}p1"

    info "Mounting system partition"
    # Mounting system partition
    mkdir mnt
    mount -t ext4 "${LOOP_DEV}p1" ./mnt/
}

copy_rootfs_sysimg() {
    if [ ! -d ./mnt/ ]; then
        fatal "System partition is not mounted !";
    fi

    info "Copying root filesystem to system partition ..."
    copy -a "${BUILD_DIR}"/* ./mnt/

    info "Installing the grub bootloader"
    grub-install --boot-directory=mnt/boot --modules=part_msdos "${LOOP_DEV}"
}

generate_vbox_vdi() {
    fatal "TODO"
}
