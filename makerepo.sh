#!/bin/bash

host_pkgs="/var/cache/apt/archives"
dist_root="/usr/local/apache2/htdocs/"
dist_pkgs=$dist_root"debian/amd64"

name="httpd"
   
check_root=$(id | awk '{print $1}' | cut -d'=' -f2 | cut -d'(' -f1)

[ $check_root -ne 0 ] && { 
    echo "Script must be run as root."; 
    exit 1; 
}

if [ ! -z $1 ] && [ $1 == "build" ] 
then
    [ ! -z $2  ] && { 
        name=$2; 
    }
    docker build -t xxdist:httpd . 1>/dev/null 2>/dev/null
    echo "Image has been built"
elif [ ! -z $1 ] 
then
    name=$1;
fi

check_build=$(docker images | grep xxdist | awk '{print $1":"$2}')

if [ -z $check_build ] || [ $check_build != "xxdist:httpd" ] 
then
   echo "Image xXdist:http doesn't exist. Build image first." 
   exit 2;
fi

docker run -d -v $host_pkgs:$dist_pkgs -p 80:80 --name $name xxdist:httpd 1>/dev/null 2>/dev/null

if [ -z $ret ]
then 
    echo "Local repository http://localhost/debian/amd64 has been launched";
else
    echo "Local repository couldn't be created !";
fi
