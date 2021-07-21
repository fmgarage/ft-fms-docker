#!/usr/bin/env bash
##!/bin/bash

# todo check if root

# todo
#set -eou pipefail

# check docker
docker -v | grep -q version || {
  printf "Docker does not appear to run, exiting.\n"
  exit 1
}

# md5 command
md5-sum() {
  if command -v md5sum >/dev/null 2>&1; then
    md5sum "$@"
  elif command -v md5 >/dev/null 2>&1; then
    md5 "$@"
  else
    printf "Error: no md5 command found\n"
    exit 1
  fi
}

# go to working dir
pwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
cd "$pwd" || exit 1
parent_dir=$(dirname "${pwd}")
inside_base_path="/opt/FileMaker/FileMaker Server/"

# parse config
source "$pwd"/../common/settings.sh

# find certificates
# todo: shorten
c_bundle=$(find . -name "*.ca-bundle")
if [[ -z $c_bundle ]]; then
  c_bundle=$(get_setting "ca-bundle" ./config.txt)
  check_many "$c_bundle"
  if [[ -n $c_bundle ]]; then
    cp -v "$c_bundle" . || exit 1
    c_bundle=${c_bundle##*/}
  fi
fi

c_cert=$(find . -name "*.crt")
if [[ -z $c_cert ]]; then
  c_cert=$(get_setting "certificate" ./config.txt)
  check_many "$c_cert"
  if [[ -n $c_cert ]]; then
    cp -v "$c_cert" . || exit 1
    c_cert=${c_cert##*/}
  fi
fi

c_key=$(find . -name "*.pem")
if [[ -z $c_key ]]; then
  c_key=$(get_setting "key-file" ./config.txt)
  check_many "$c_key"
  if [[ -n $c_key ]]; then
    cp -v "$c_key" . || exit 1
    c_key=${c_key##*/}
  fi
fi

# get settings from config
assisted_install=$(get_setting "assisted_install" ./config.txt)
check_setting "$assisted_install"
# todo not found
start_server=$(get_setting "start_server" ./config.txt)
remove_build_dir=$(get_setting "remove_build_dir" ./config.txt)
admin_user=$(get_setting "Admin Console User" ./"$assisted_install")
admin_pass=$(get_setting "Admin Console Password" ./"$assisted_install")

# set instance id
#while [ $is_valid -eq 0 ] && [ $old_container -eq 1 ]; do
printf "Please enter a name or leave empty for an automatic ID to be assigned to this instance: "
read -r user_input

case $user_input in
"")
  # todo while valid (check if exists)
  instance_id=$(uuidgen | md5-sum "$@" | cut -c-12) || {
    printf "error while generating instance id\n"
    exit 1
  }
  echo "id: " "$instance_id"
  ;;
*[!abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_.-]*)
  echo >&2 "That ID is not allowed. Please use only characters [a-zA-Z0-9_.-]"
  exit 1
  ;;
*)
  # todo while valid (check if exists)
  instance_id=$user_input
  ;;
esac
#done

# write to .env
echo "ID=${instance_id}" >../.env

# Load paths
source "$pwd"/../common/paths.sh

# download filemaker_server package
package_remove=0
# look for installer locally
package=$(find . -name "*.deb" -o -name "*.rpm")

# download from URL if not found locally
if [[ ! $package ]]; then
  printf "\ndownloading fms package ...\n"
  url=$(get_setting "url" ./config.txt)
  STATUS=$(curl -s --head --output /dev/null -w '%{http_code}' "$url")
  if [ ! "$STATUS" -eq 200 ]; then
    echo "Error while downloading fms package: Got a $STATUS from URL: $url ..."
    exit 1
  fi
  curl "${url}" -O || exit
  package_remove=1
fi

# find deb or rpm, set image_name according to installer package
package=$(find . -name "*.deb")
image_name=ubuntu-fms-19_3
# todo pin version tag / digest
base_image=jrei/systemd-ubuntu:18.04
helper_script="helper_ubuntu.sh"
if [[ ! $package ]]; then
  package=$(find . -name "*.rpm")
  image_name=centos-fms-19_2
  # todo pin version tag / digest
  base_image=jrei/systemd-centos:7
  helper_script="helper_centos.sh"
fi

plines=$(wc -l <<<"$package")
if [[ $plines -gt 1 ]]; then
  printf "%s fmserver packages found, 1 expected\n" "$plines"
  exit 1
fi

# write to .env
echo "IMAGE=${image_name}" >>../.env

service_name=fms
container_name=fms-${instance_id}
build_image_name=fmsinstall
date=$(date +%Y-%m-%d)
source ../common/get_tz.sh
if ! timezone=$(get_tz); then
  >&2 echo "error getting timezone\n"
  exit 1
fi


# check if container names are in use
old_container=0
rm_service=0
docker ps -aq --filter "name=${container_name}" | grep -q . && old_container=1
is_valid=0
while [ $is_valid -eq 0 ] && [ $old_container -eq 1 ]; do
  # todo reuse service
  echo Another "${container_name}" container already exists, remove and build a new image? [y/n]
  read remove_service

  case $remove_service in
  Y | y)
    is_valid=1
    rm_service=1
    ;;
  N | n)
    is_valid=1
    rm_service=0
    ;;
  *)
    echo Please enter [y]es or [n]o
    ;;
  esac
done

if [ $old_container -eq 1 ] && [ $rm_service -eq 1 ]; then
  printf "\nstopping...\n"
  docker stop "${container_name}"
  printf "\nremoving...\n"
  docker rm "${container_name}"
elif [ $old_container -eq 1 ] && [ $rm_service -eq 0 ]; then
  printf "\n Exiting.\n"
  exit 0
fi

if docker ps -aq --filter "name=${build_image_name}" | grep -q .; then
  echo another build container already exists, removing...
  docker stop $build_image_name
  docker rm $build_image_name
fi

# create bind volumes
printf "\n\e[36mCreating directories on host...\e[39m\n"
for ((i = 1; i < "${#paths[@]}"; i += 2)); do
  if [[ ! -d "$parent_dir/fms-data${paths[$i]}" ]]; then
    mkdir -p -- "$parent_dir/fms-data${paths[$i]}"
  fi
done

printf "\n\e[36mcreating docker volumes...\e[39m\n"
for ((i = 0; i < "${#paths[@]}"; i += 2)); do
  docker volume create --driver local -o o=bind -o type=none -o device="$parent_dir/fms-data${paths[$i + 1]}" "${paths[$i]}" || {
    printf "error while creating docker volumes\n"
    exit 1
  }
done

printf "\n"

# run build container
docker run -d \
  --name $build_image_name \
  --cap-add=SYS_ADMIN \
  -e CERT_CERT="$c_cert" \
  -e CERT_BUNDLE="$c_bundle" \
  -e CERT_KEY="$c_key" \
  -e PACKAGE_REMOVE="$package_remove" \
  -e ASSISTED_INSTALL="$assisted_install" \
  -e FMS_ADMIN_USER="$admin_user" \
  -e FMS_ADMIN_PASS="$admin_pass" \
  -e TIMEZONE="$timezone" \
  --tmpfs /tmp \
  --tmpfs /run \
  --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v "${pwd}":/root/build/ \
  -v fms-admin-conf-"${instance_id}":"/opt/FileMaker/FileMaker Server/Admin/conf":delegated \
  -v fms-conf-"${instance_id}":"/opt/FileMaker/FileMaker Server/conf":delegated \
  -v fms-data-backups-"${instance_id}":"/opt/FileMaker/FileMaker Server/Data/Backups":delegated \
  -v fms-data-databases-"${instance_id}":"/opt/FileMaker/FileMaker Server/Data/Databases":delegated \
  -v fms-data-preferences-"${instance_id}":"/opt/FileMaker/FileMaker Server/Data/Preferences":delegated \
  -v fms-data-scripts-"${instance_id}":"/opt/FileMaker/FileMaker Server/Data/Scripts":delegated \
  -v fms-dbserver-extensions-"${instance_id}":"/opt/FileMaker/FileMaker Server/Database Server/Extensions/":delegated \
  -v fms-http-dotconf-"${instance_id}":"/opt/FileMaker/FileMaker Server/HTTPServer/.conf":delegated \
  -v fms-http-conf-"${instance_id}":"/opt/FileMaker/FileMaker Server/HTTPServer/conf":delegated \
  -v fms-http-logs-"${instance_id}":"/opt/FileMaker/FileMaker Server/HTTPServer/logs":delegated \
  -v fms-logs-"${instance_id}":"/opt/FileMaker/FileMaker Server/Logs":delegated \
  -v fms-webpub-conf-"${instance_id}":"/opt/FileMaker/FileMaker Server/Web Publishing/conf":delegated \
  "$base_image" || {
  printf "error while running build container\n"
  exit 1
}

# run install script inside build container
docker exec $build_image_name /root/build/$helper_script
if [ ! $? ]; then
  printf "error while installing!\n"
  docker stop $build_image_name
  docker rm $build_image_name
  exit 1
fi

# check for flag file
build_success=$(find . -name build_success)
if [[ ! $build_success ]]; then
  printf "build not successful\n"
  printf "stopping & removing build container ...\n"
  docker stop $build_image_name
  docker rm $build_image_name
  exit 1
fi

# remove flag file
rm "$build_success" || exit 1

# docker commit
printf "\ncommit build container to new image ...\n"
docker commit -c "EXPOSE 80" -c "EXPOSE 443" -c "EXPOSE 2399" -c "EXPOSE 5003" -c "EXPOSE 16000-16002" \
  --change "ENV CERT_CERT=''" \
  --change "ENV CERT_BUNDLE=''" \
  --change "ENV CERT_KEY=''" \
  --change "ENV PACKAGE_REMOVE=''" \
  --change "ENV ASSISTED_INSTALL=''" \
  --change "ENV FMS_ADMIN_USER=''" \
  --change "ENV FMS_ADMIN_PASS=''" \
  "${build_image_name}" "${image_name}":"${date}"
docker tag $image_name:"${date}" "${image_name}":latest

# remove $build...
printf "\nremoving build container ...\n"
docker stop $build_image_name && docker rm $build_image_name

# todo
# backup/zip fms-data directory

# check if fms network exists
network=0
docker network ls -q --filter "name=^fms-net$" | grep -q . && network=1
case $network in
0)
  echo "Network fms-net not found, will be created\n"
  compose_files="-f ../docker-compose.yml -f ../fms-network.yml"
  ;;
1)
  compose_files="-f ../docker-compose.yml"
  ;;
*)
  printf "error while looking for fms docker network: %s" "$(docker network ls -q --filter "name=fms-net")"
  exit 1
  ;;
esac

if [[ $start_server -eq 1 ]]; then
  printf "\nDone. Now starting your server ....\n"
  docker-compose $compose_files up -d $service_name
else
  compose_files=$(sed 's/..\///g' <<<"$compose_files")
  printf "\nDone. You can now start your server with\e[36m ./tools/start_server\e[39m or \e[36mdocker-compose %s up [-d] %s\e[39m\n" "$compose_files" "$service_name"
fi

exit 0
