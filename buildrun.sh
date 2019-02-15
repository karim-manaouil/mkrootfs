#!/bin/sh

if [ $1 -eq "build" ]; then
    docker build -t dist:httpd .
fi

host_pkgs="/var/cache/apt/archives"
dist_root="/usr/local/apache2/htdocs/"
dist_pkgs=$dist_root"debian/amd64"

name="httpd"

if [ ! -z $2 ]; then
    name=$2;
fi

check_build=$(docker images | grep dist | awk '{print $1":"$2}')

if [ $check_build -eq "dist:httpd" ]; then
    
fi

docker run -d -v $host_pkgs:$dist_pkgs --name $name -p 80:80 httpd
