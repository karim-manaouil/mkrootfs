#!/bin/bash

# This file uses the routines from stderr.sh 
# which are available upon the inclusion of
# stderr.sh in buildrun.sh

BASE="/home/afr0ck/Desktop/ENVL/gen-dist/"

HOST_PACKAGES="${BASE}packages/"

SERVER_ROOT="/usr/local/apache2/htdocs/"

SERVER_PACKAGES="${SERVER_ROOT}debian/amd64"

CONTAINER="xxdisthttpd"

PORT="8778"

img_exists=$(docker images -q -f  reference=xxdist:httpd)

if [ -z $img_exists ]; then 
    info "Building image to serve local repository ...";
    docker build -t xxdist:httpd . >/dev/null 2>&1
fi

img_running=$(docker ps -q -f name=xxdisthttpd -f status=running)

if [ ! -z $img_running ]; then
    info "Stopping and removing currently running server"
    docker stop $img_running >/dev/null 2>&1;
    docker rm $img_running >/dev/null 2>&1;
fi

info "Creating apt index ..."
dpkg-scanpackages "${HOST_PACKAGES}" /dev/null 2>/dev/null \
    | gzip -9c > "${HOST_PACKAGES}Packages.gz" 2>/dev/null

info "Creating private sources.list"
mv /etc/apt/sources.list /etc/apt/sources.list.xxdisthttpd.backup
echo "deb [trusted=true] http://localhost:${PORT}/debian/amd64 /" > /etc/apt/sources.list

info "Starting local apt server ..."
docker run -d -p "${PORT}":80 -v "${HOST_PACKAGES}":"${SERVER_PACKAGES}" \
    --name xxdisthttpd xxdist:httpd >/dev/null 2>&1

