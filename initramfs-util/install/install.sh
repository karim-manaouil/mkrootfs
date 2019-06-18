#!/bin/bash

DISK=

create_partitions_and_mount() 
{
    local fs=
    local mnt=$2

    DISK=$1

    info "creating partition on $DISK"

    if ! fdisk -l | grep -q "$DISK"; then 
       echo "$DISK not found. Exiting ..."
       exit 
    fi

    printf "o\nn\np\n1\n\n\nw\n" | fdisk "$DISK" 1>/dev/null 2>&1

    [ "$?" -ne 0 ] && fatal "Error while partitionning !"
    
    fs="${DISK}1"

    info "Formatting ${fs} with ext4 ..."
    mkfs.ext4 "${fs}" 1>/dev/null 2>/dev/null

    [ "$?" -ne 0 ] && fatal "Cannot format partition !"

    info "Mounting rootfs $fs at $mnt"

    [ ! -d "$mnt" ] && mkdir $mnt
    mount -t ext4 $fs $mnt 1>/dev/null 2>/dev/null
    
    [ "$?" -ne 0 ] && fatal "Cannot mount partition !"

}

copy_rootfs_to_disk() 
{
    local rootfsdir=$1
    local mnt=$2

    if [ ! -d "$mnt" ]; then
        fatal "System partition is not mounted !";
    fi

    info "Copying root filesystem to system partition ..."
    cp -a "$rootfsdir"* "$mnt"

    [ "$?" -ne 0 ] && fatal "Aborting. Error while copying !"

    info "Installing the grub bootloader ..."

    mount -B /proc  ""$mnt"proc"    2>/dev/null 1>&2
    mount -B /sys   ""$mnt"sys"     2>/dev/null 1>&2
    mount -B /dev   ""$mnt"dev"     2>/dev/null 1>&2

    LC_ALL=C  chroot "$mnt" grub-install --modules=part_msdos $DISK >/dev/null 2>&1
    LC_ALL=C  chroot "$mnt" grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1

    [ "$?" -ne 0 ] && fatal "Could not install grub2 !"
}

finish_installation() 
{
    umount ""$mnt"proc"
    umount ""$mnt"sys"
    umount ""$mnt"dev"
    umount "$mnt"
    umount /install_root
    umount /cdrom
    losetup -d loop0

    info "Installation finished ! You can, now, reboot your system."
}

. stderr.sh

info "Creating system partition ..."

[ "$#" != "1" ] && fatal "Missing arguments !"

mkdir cdrom
mount -t iso9660 /dev/sr0 cdrom

losetup -f /cdrom/rootfs.sq
mkdir install_root
mount -t squashfs /dev/loop0 install_root

create_partitions_and_mount $1 /install_disk
copy_rootfs_to_disk /install_root/ /install_disk/

info "Installation finished successfully."
info "Rebooting in 3 seconds ..."

sleep 3
reboot


