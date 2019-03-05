#!/bin/bash

# This file is a modified version of the official LFS mkinitramfs GPL script

copy()
{
  local file

  if [ "$2" == "lib" ]; then
    # sometimes a lib is found in multiple dirs.
    # And start with lib64 because of ld-linux. 
    file=$(find /lib64 /lib /usr/lib -name $1 | head -n1) 
  else
    file=$(type -p $1)
  fi

  if [ -n $file ] ; then
    cp $file $WDIR$file
  else
    echo "Missing required file: $1 for directory $2"
    rm -rf $WDIR
    exit 1
  fi
}

# $1=$unsorted $2=$WDIR
cleanup() 
{
    rm $1

    if [[ -z ${2%%/tmp/*} ]]; then
        rm -rf $2 
    fi
}

if [ $(id -u) -ne 0 ]; then 
    echo "Must be run as root !"; exit 1;
fi

KERNEL_VERSION=$(uname -r)

INITRAMFS_FILE=initrd-$KERNEL_VERSION

printf "Creating $INITRAMFS_FILE... "

binfiles="busybox"

if [ -x /bin/udevadm ] ; then binfiles="$binfiles udevadm"; fi

sbinfiles="modprobe blkid switch_root mkfs.ext4 fdisk losetup"

for f in mdadm mdmon udevd udevadm; do
  if [ -x /sbin/$f ] ; then sbinfiles="$sbinfiles $f"; fi
done

unsorted=$(mktemp /tmp/unsorted.XXXXXXXXXX)

WDIR=

if [ -n $1 ]; then
    WDIR="initramfs"
else
    WDIR=$(mktemp -d /tmp/initrd-work.XXXXXXXXXX)
fi

# Create base directory structure
mkdir -p $WDIR/{bin,dev,lib/firmware,lib/x86_64-linux-gnu}
mkdir -p $WDIR/{lib64,run,sbin,sys,proc,usr}
mkdir -p $WDIR/etc/{modprobe.d,udev/rules.d}
touch $WDIR/etc/modprobe.d/modprobe.conf

mknod -m 640 $WDIR/dev/console c 5 1
mknod -m 664 $WDIR/dev/null    c 1 3

if [ -f /etc/udev/udev.conf ]; then
  cp /etc/udev/udev.conf $WDIR/etc/udev/udev.conf
fi

for file in $(find /etc/udev/rules.d/ -type f) ; do
  cp $file $WDIR/etc/udev/rules.d
done

if [ -d /lib/firmware ]; then
    cp -a /lib/firmware $WDIR/lib
fi

install -m0755 init/init $WDIR/init

if [  -n "$KERNEL_VERSION" ] ; then
  if [ -x /bin/kmod ] ; then
    binfiles="$binfiles kmod"
  else
    binfiles="$binfiles lsmod"
    sbinfiles="$sbinfiles insmod"
  fi
fi

for f in $binfiles ; do
  if [ -e /bin/$f ]; then d="/bin"; else d="/usr/bin"; fi
  ldd $d/$f | sed "s/\t//" | cut -d " " -f1 | sed "s/\/lib64\///" >> $unsorted
  copy $d/$f bin
done

for f in $sbinfiles ; do
  ldd /sbin/$f | sed "s/\t//" | cut -d " " -f1 | sed "s/\/lib64\///" >> $unsorted
  copy $f sbin
done

if [ -x /lib/udev/udevd ] ; then
  ldd /lib/udev/udevd | sed "s/\t//" | cut -d " " -f1 | sed "s/\/lib64\///" >> $unsorted
elif [ -x /lib/systemd/systemd-udevd ] ; then
  ldd /lib/systemd/systemd-udevd | sed "s/\t//" | cut -d " " -f1 | sed "s/\/lib64\///" >> $unsorted
fi

pushd $WDIR/bin

for bin in $(busybox --list); do
    ln -s busybox $bin
done

popd

sort $unsorted | uniq | while read library ; do
  if [ "$library" == "linux-vdso.so.1" ] ||
     [ "$library" == "linux-gate.so.1" ]; then
    continue
  fi
    
  copy $library lib
done

if [ -d /lib/udev ]; then
  cp -a /lib/udev $WDIR/lib
fi
if [ -d /lib/systemd ]; then
  cp -a /lib/systemd $WDIR/lib
fi

if [ -n "$KERNEL_VERSION" ]; then
  find                                                                        \
     /lib/modules/$KERNEL_VERSION/kernel/{crypto,fs,lib}                      \
     /lib/modules/$KERNEL_VERSION/kernel/drivers/{block,ata,md,firewire}      \
     /lib/modules/$KERNEL_VERSION/kernel/drivers/{scsi,message,pcmcia,virtio} \
     /lib/modules/$KERNEL_VERSION/kernel/drivers/usb/{host,storage}           \
     -type f 2> /dev/null | cpio --make-directories -p --quiet $WDIR

  cp /lib/modules/$KERNEL_VERSION/modules.{builtin,order}                     \
            $WDIR/lib/modules/$KERNEL_VERSION

  depmod -b $WDIR $KERNEL_VERSION
fi

if [[ ! -z $2 ]]; then
    ( cd $WDIR ; find . | cpio -o -H newc --quiet | gzip -9 ) > $INITRAMFS_FILE
fi

echo 

cleanup $unsorted $WDIR

printf "done.\n"

