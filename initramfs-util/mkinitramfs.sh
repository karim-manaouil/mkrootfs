#!/bin/bash

BUILDROOT=
INITRD=

BINARIES="busybox fdisk"
MODULES="ahci sd_mod virtio_blk virtio_pci" 
MODULES="$MODULES ext4 squashf"

SOBJS="/tmp/mkinitramfs-SHARED-objects-UNSORTED"

parse_cmdline() 
{
    while (( $# )); do
        case $1 in
            -f)
                INITRD="$2"
                shift 2
                ;;
            -d)
                BUILDROOT="$2"
                shift 2
                ;;
            -b)
                IFS=, read -r -a bins <<< "$2"
                for bin in ${bins[@]}; do
                    BINARIES+=("$bin")
                done
                unset bins
                shift 2
                ;;
            *)
               fatal "unknown option $1" 
        esac                                
    done   
}

setup_initrd_rootfs()
{   
    if [[ -d $BUILDROOT ]] && [[ ! -w $BUILDROOT ]]; then
        fatal "Directory $BUILDROOT exists but not writable !"

    elif [[ ! -d $BUILDROOT ]] && ([[ -e $BUILDROOT ]] || [[ ! -w ${BUILDROOT##*/} ]]); then
        fatal "File $BUILDROOT exists or ${BUILDROOT##*/} is not writable !"
    fi;

    [[ ! -d $BUILDROOT ]] && mkdir $BUILDROOT

    mkdir -p $BUILDROOT{boot,bin,sbin,root,usr,sys,dev}
    mkdir -p $BUILDROOT{proc,lib/x86_64-linux-gnu,lib64}  
}

copy_file()
{
    local src=$1 dst=$2
   
    [[ ! -d ${src%/*} ]] && mkdir -p ${src%/*}

    # -p to preserve access rights + ownership 
    cp -p $src $dst 
}

install_binaries() 
{
    # get lib path from ldd output
    local regex="(.*) (\/.*) \(.*\)";  
    
    for bin in ${BINARIES[@]}; 
    do
        binpath=$(which $bin >/dev/null)        
        [[ -z $binpath ]] && fatal "binary $bin doesn't exist, aborting."

        copy_file $binpath $binpath 
                       
        while read -r var; 
        do 
            if [[ $var =~ $regex ]]; then
                echo ${BASH_REMATCH[2]} >> "$SOBJS"
            fi
        done <<< $(ldd /bin/ls)
    done
}


install_sobjs()
{
}

. stderr.sh

touch "$SOBJS"

parse_cmdline $@

BUILDROOT="${BUILDROOT:-initramfs/}"
INITRD="${INITRD:-initrd.gz}"

setup_initrd_rootfs
install_binaries
install_sobjs
install_modules
