#!/usr/bin/env bash


# go to working dir
cd "${0%/*}" || exit

pwd=$(pwd)
build_image_name=fmsinstall
image_name=centos-fms-19_2
date=$(date +%Y-%m-%d)

# check if container names are in use
docker ps -aq --filter "name=${build_image_name}" | grep -q . && echo another build container already exists && exit 1 || printf "\r"
docker ps -aq --filter "name=fmserver" | grep -q . && echo another fmserver container already exists && docker stop fmserver && docker rm fmserver || printf "\r"
# docker ps -aq --filter "name=fmserver" | grep -q . && echo another fmserver container already exists && exit 1 || printf "\r"

# build container
docker run -d --name $build_image_name --cap-add=SYS_ADMIN --tmpfs /tmp --tmpfs /run --tmpfs /run/lock -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v "${pwd}":/root/build/ jrei/systemd-centos:7

# run install script in build container
docker exec -ti $build_image_name /root/build/install_fms.sh

# docker commit
printf "\ncommit build container to new image ...\n"
docker commit -c "EXPOSE 80" -c "EXPOSE 443" -c "EXPOSE 2399" -c "EXPOSE 5003" -c "EXPOSE 16000-16002" "${build_image_name}" "${image_name}":"${date}"
docker tag $image_name:"${date}" "${image_name}":latest

# remove $build...
printf "\nremoving build container ...\n"
docker stop $build_image_name && docker rm $build_image_name

# start fmserver
# TODO mount Databases
# printf "\nstart filemaker server container ...\n"
# docker run -d --name fmserver --cap-add=SYS_ADMIN --tmpfs /tmp --tmpfs /run --tmpfs /run/lock -v /sys/fs/cgroup:/sys/fs/cgroup:ro -p 5003:5003 -p 16000-16002:16000-16002 -p 80:80 -p 443:443 $image_name:latest || exit 1

# check
# printf "\ncheck port 16000 ...\n"
# curl 127.0.0.1:16000

printf "\ndone\n"
