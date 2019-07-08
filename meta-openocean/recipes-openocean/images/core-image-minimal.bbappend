IMAGE_INSTALL += "packagegroup-lxde-base networkmanager networkmanager-nmtui vim-tiny remmina tigervnc openssh"
IMAGE_FEATURES += "x11"
EXTRA_IMAGE_FEATURES += " package-management "
PACKAGE_FEED_URIS += " "
DISTRO_FEATURES_append = " wifi"

