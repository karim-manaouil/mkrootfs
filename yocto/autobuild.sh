#!/bin/bash

if [ $(id -u) -eq 0 ]; then
    echo -e "\e[31mPlease don't run as root!\e[0m"
else
    VERSION=""
    # Setting the build version
    [ "$#" -eq "1" ] && VERSION="$1" || VERSION="latest"

    # Building the Yocto Docker Image
    docker build --build-arg "host-uid=$(id -u)" --build-arg "host-gid=$(id -g)" --tag "openocean-image:$VERSION" .

    # Running the Yocto Docker Image
    mkdir -p yocto/output
    docker run -it --rm -v $PWD/yocto/output:/home/openocean/yocto/output openocean-image:$VERSION /bin/bash
fi
