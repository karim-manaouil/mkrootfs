#!/bin/bash

BUILDROOT=
INITRD=

BINARIES="busybox fdisk"
MODULES="ahci sd_mod virtio_blk virtio_pci" 
MODULES="$MODULES ext4 squashfs"

DEPS=() # $MODULES with their deps

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
    if [ ! -d "$BUILDROOT" ]; then 
        mkdir $BUILDROOT
        [[  $? != 0 ]] && fatal "Cannot create $BUILDROOT"
    fi

    mkdir -p "$BUILDROOT"{boot,bin,sbin,root,usr,sys,dev}
    mkdir -p "$BUILDROOT"{proc,lib/x86_64-linux-gnu,lib64}  
}

copy_file()
{
    local src=$1 dst=$2
    local dstpath=$BUILDROOT$dst
    

    echo "copying ${dst##*/} to ${dstpath%\/*}"
    
    if [[ ! -d ${dstpath%\/*} ]]; then 
        echo "creating ${dstpath%\/*}"
        mkdir -p ${dstpath%\/*}
    fi

    # -p to preserve access rights + ownership 
    cp -p "$src" "$dstpath"
}

install_binaries() 
{
    # get lib path from ldd output
    local regex="(.*) (\/.*) \(.*\)";  
    
    for bin in ${BINARIES[@]}; 
    do
        binpath=$(which $bin)        
        [[ -z $binpath ]] && fatal "binary $bin doesn't exist, aborting."

        copy_file "$binpath" "${binpath:1}"
                       
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
    sos=$(echo "$SOBJS" | sort | uniq)

    for so in ${sos[@]}; do
        if [[ ! -e $BUILDROOT${so:1} ]]; then
            copy_file "$so" "${so:1}"
        fi
    done
}

exists_in_list() 
{
    local obj=$1 list=${@:2}

    for e in ${list[@]}; do
        [[ $e == $obj ]] && return 0
    done

    return 1
}

add_module_dependency()
{
    IFS=, read -a deps <<<  $(modinfo -F depends $1)
    IFS=, read -a sdep <<<  $(modinfo -F softdep $1 | cut -d: -f2)
   
    for dep in ${deps[@]} ${sdep[@]};
    do
        if ! exists_in_list $dep ${DEPS[@]}; then
            DEPS+=("$dep")
        fi
    done
}

resolve_modules_deps()
{
   for mod in $MODULES; 
   do
        if ! $(modinfo $mod > /dev/null); then
            fatal "module $mod doesn't exist on host, aborting."
        fi 

        DEPS+=("$mod")
        add_module_dependency "$mod"
   done
}

install_modules() 
{
    # After this use DEPS instead of MODULES
    resolve_modules_deps

    for mod in ${DEPS[@]}; 
    do
        modpath=$(modinfo -F filename "$mod")
        copy_file "$modpath" "${modpath:1}"
    done
}

################ Start build ##################

. stderr.sh

touch "$SOBJS"

parse_cmdline $@

BUILDROOT="${BUILDROOT:-initramfs/}"
INITRD="${INITRD:-initrd.gz}"

info "Building initramfs image $INITRD ..."

setup_initrd_rootfs
install_binaries
install_sobjs
install_modules

info "Build finished successfully"
