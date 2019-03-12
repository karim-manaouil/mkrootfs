#!/bin/bash

BUILDROOT=
INITRD=

BINARIES="busybox:expand_busybox fdisk"
MODULES="ahci sd_mod sr_mod virtio_blk virtio_pci" 
MODULES="$MODULES loop ext4 isofs squashfs"

LIBPATHS=()
DEPS=() # $MODULES with their deps

KERNEL_VERSION=$(uname -r)

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
            -m)
                IFS=, read -r -a mods <<< "$2"
                for mod in ${mods[@]}; do
                    MODULES+=("$mod")
                done
                unset mods
                shift 2
                ;;
            -k)
                KERNEL_VERSION=$2
                shift 2
                ;;
            *)
               fatal "unknown option $1" 
        esac                                
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

copy_file()
{
    local src=$1 dst=$2
    local dstpath=$BUILDROOT$dst
        
    if [[ ! -d ${dstpath%\/*} ]]; then 
        mkdir -p ${dstpath%\/*}
    fi

    # -p to preserve access rights + ownership 
    cp -p "$src" "$dstpath"
}

run_procs()
{
    # Some security
    local is_func=

    for proc in $@; do
        is_func=$(LC_ALL=C type -t "$proc")
        if [[ -n $is_func ]] && [[ $is_func == "function" ]]; then
            $proc
        fi
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

install_binaries() 
{
    local regex="(.*) (\/.*) \(.*\)";  # get lib path from ldd output
    local ddotsep="([^:]*):([^:]*)";
    local procs=() # function names to run later

    for bin in ${BINARIES[@]}; 
    do
        if [[ $bin =~ $ddotsep ]]; then
            name="${BASH_REMATCH[1]}"
            procs+=("${BASH_REMATCH[2]}");
        else
            name=$bin
        fi

        binpath=$(which $name)        
        [[ -z $binpath ]] && fatal "binary $bin doesn't exist, aborting."

        copy_file "$binpath" "${binpath:1}"
                       
        while read -r var; 
        do 
            if [[ $var =~ $regex ]]; then
                if ! exists_in_list ${BASH_REMATCH[2]} ${LIBPATHS[@]}; then
                    LIBPATHS+=("${BASH_REMATCH[2]}")
                fi
            fi
        done <<< $(ldd $binpath)
    done

    run_procs ${procs[@]}
}

install_sobjs()
{
    for so in ${LIBPATHS[@]}; do
        if [[ ! -e $BUILDROOT${so:1} ]]; then
            copy_file "$so" "${so:1}"
        fi
    done
    
    # Handling Stretch quirks
    if [[ -e /etc/os-release ]]; then
        cat /etc/os-release | grep -q stretch
        [[ $? == 0 ]] && \
            copy_file /lib64/ld-linux-x86-64.so.2 lib64/ld-linux-x86-64.so.2
    fi
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
        # modpath can sometimes contain more
        # than one path
        modpath=$(modinfo -F filename "$mod")
        for path in ${modpath[@]}; do 
            copy_file "$path" "${path:1}"
        done;
    done
}

################ Start build ##################

. stderr.sh

[[ $(id -u) != 0 ]] && \
    fatal "Script needs root permissions to complete."

. uprocs.sh

parse_cmdline $@

BUILDROOT="${BUILDROOT:-initramfs/}"
INITRD="${INITRD:-initrd.gz}"

info "Building initramfs image $INITRD ..."
setup_initrd_rootfs

info "Installing binaries ..." && install_binaries
info "Installing shared objects ..." && install_sobjs
info "Installing modules with their dependency ..." && install_modules

copy_file init/init init
depmod -b ${BUILDROOT%\/} $KERNEL_VERSION 2>/dev/null

info "Generating $INITRD ..."

( cd $BUILDROOT ; find . | cpio -o -H newc --quiet | gzip -9 ) > $INITRD

info "Build finished successfully"
