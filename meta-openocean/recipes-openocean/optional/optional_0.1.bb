SUMMARY = "bitbake-layers recipe"
DESCRIPTION = "Recipe created by bitbake-layers"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://LICENSE;md5=96af5705d6f64a88e035781ef00e98a8"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}-${PV}:"

SRCREV  = "master"
SRC_URI = "git://github.com/DynamicDevices/bbexample.git"

S = "${WORKDIR}/git"

PARALLEL_MAKE = ""

inherit autotools
