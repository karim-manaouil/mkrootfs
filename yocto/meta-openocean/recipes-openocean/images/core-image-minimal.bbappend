#IMAGE_INSTALL += "packagegroup-lxde-base sudo" 
#IMAGE_INSTALL += "networkmanager networkmanager-nmtui vim-tiny remmina tigervnc openssh freerdp"
#IMAGE_INSTALL += "gedit epiphany"
#IMAGE_FEATURES += "x11" 
#IMAGE_FEATURES += "package-management dev-pkgs tools-sdk"

#DISTRO_FEATURES += "wifi keyboard"

PACKAGE_FEED_URIS += " "

# Uncomment those to replace sysvinit by systemd
DISTRO_FEATURES_append = " systemd"
VIRTUAL_RUNTIME_init_manager = "systemd"
DISTRO_FEATURES_BACKFULL_CONSIDERED = "sysvinit"
VIRTUAL_RUNTIME_initscripts = ""

inherit extrausers

EXTRA_USERS_PARAMS = "\
    usermod -p `openssl passwd oocean` root; \
    useradd -p `openssl passwd oocean` openocean; \
    "

post_process_script() {
    echo "deb http://deb.debian.org/debian stretch main contrib non-free" \
        > ${IMAGE_ROOTFS}/etc/apt/sources.list 
}

ROOTFS_POSTPROCESS_COMMAND += "post_process_script;"
