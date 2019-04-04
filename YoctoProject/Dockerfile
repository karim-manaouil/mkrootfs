FROM ubuntu:16.04

# Upgrading system and installing Yocto Project basic dependencies
RUN apt-get update && apt-get -y upgrade && apt-get -y install gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat cpio python python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping libsdl1.2-dev xterm tar locales vim

# Seting up locales (Yocto build fails without any locale set)
RUN locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Cleaning up APT
###RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Replacing dash with bash (Ubuntu, by default, uses dash as an alias for sh)
RUN rm /bin/sh && ln -s bash /bin/sh


# Initializing Environment Variables
ENV USER_NAME openocean
ENV PROJECT openocean
ENV YOCTO_SRC_DIR /home/$USER_NAME/yocto/src
ENV YOCTO_OUTPUT_DIR /home/$USER_NAME/yocto/output
ENV YOCTO_RELEASE "thud"

# Managing user
ARG host_uid=1000
ARG host_gid=1000 
RUN groupadd -g $host_gid $USER_NAME && useradd -u $host_uid -g $host_gid -ms /bin/bash $USER_NAME  

# Switching to user 
USER $USER_NAME

# Creating the directory structure
RUN mkdir -p $YOCTO_SRC_DIR  $YOCTO_OUTPUT_DIR 
 
# Installing Yocto Project
WORKDIR $YOCTO_SRC_DIR
RUN git clone --branch ${YOCTO_RELEASE} git://git.yoctoproject.org/poky 

# Build
WORKDIR $YOCTO_OUTPUT_DIR
ENV TEMPLATECONF=$YOCTO_SRC_DIR/poky/meta-poky/conf
#CMD source $YOCTO_SRC_DIR/poky/oe-init-build-env && bitbake $PROJECT-image-1.0 


