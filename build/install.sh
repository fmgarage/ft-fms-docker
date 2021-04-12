#!/usr/bin/env bash
##!/bin/bash

# go to working dir
pwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
cd "$pwd" || exit 1
parent_dir=$(dirname "${pwd}")
inside_base_path="/opt/FileMaker/FileMaker Server/"

# volume-paths array
paths=( \
  "data-admin-conf" "/Admin/conf/" \
  "data-data-backups" "/Data/Backups/" \
  "data-data-databases" "/Data/Databases/" \
  "data-data-preferences" "/Data/Preferences/" \
  "data-dbserver-extensions" "/Database Server/Extensions/"
  "data-conf" "/conf/" \
  "data-http-dotconf" "/HTTPServer/.conf/"
  "data-http-conf" "/HTTPServer/conf/" \
  "data-http-logs" "/HTTPServer/logs/"
  "data-logs" "/Logs/" \
  "data-webpub-conf" "/Web Publishing/conf/"
)

# parse config
function get_setting() {
  grep -Ev '^\s*$|^\s*\#' "$2" | grep -E "\s*$1\s*=" | sed 's/.*=//; s/^ //g'
}

function check_setting() {
  if [[ $(wc -l <<<"$1") -gt 1 ]]; then
    echo "multiple values found, 1 expected" >&2
    exit 1
  fi
}

# find certificates
# todo: shorten
c_bundle=$(find . -name "*.ca-bundle")
if [[ ! $c_bundle ]]; then
  c_bundle=$(get_setting "ca-bundle" ./config.txt)
  check_setting "$c_bundle"
  if [[ $c_bundle ]]; then
    cp -v "$c_bundle" . || exit 1
    c_bundle=${c_bundle##*/}
  fi
fi

c_cert=$(find . -name "*.crt")
if [[ ! $c_cert ]]; then
  c_cert=$(get_setting "certificate" ./config.txt)
  check_setting "$c_cert"
  if [[ $c_cert ]]; then
    cp -v "$c_cert" . || exit 1
    c_cert=${c_cert##*/}
  fi
fi

c_key=$(find . -name "*.pem")
if [[ ! $c_key ]]; then
  c_key=$(get_setting "key-file" ./config.txt)
  check_setting "$c_key"
  if [[ $c_key ]]; then
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

if [[ ! $c_cert ]] || [[ ! $c_bundle ]] || [[ ! $c_key ]]; then
  image_name=centos-fms-19_2
  service_name=fms
else
  image_name=centos-fms-c-19_2
  service_name=fms-c
fi

build_image_name=fmsinstall
# todo pin version tag / digest
base_image=jrei/systemd-centos:7
date=$(date +%Y-%m-%d)

# download filemaker_server package
package_remove=0
package=$(find . -name "*.rpm")
plines=$(wc -l <<<"$package")
if [[ ! $package ]]; then
  printf "\ndownloading fms package ...\n"
  url=$(get_setting "url" ./config.txt)
  STATUS=$(curl -s --head --output /dev/null -w '%{http_code}' "$url")
  if [ ! $STATUS -eq 200 ]; then
    echo "Got a $STATUS from URL: $url ..."
    exit
  fi
  curl "${url}" -O || exit
  package_remove=1
elif [[ $plines -gt 1 ]]; then
  printf "%s rpm packages found, 1 expected" "$plines"
  exit 1
fi

# check if container names are in use
old_container=0
rm_service=0
docker ps -aq --filter "name=${service_name}" | grep -q . && old_container=1
is_valid=0
while [ $is_valid -eq 0 ] && [ $old_container -eq 1 ]; do
  echo Another ${service_name} container already exists, remove and build a new image? [y/n]
  read remove_service

  case $remove_service in
    Y|y)
      is_valid=1
      rm_service=1
      ;;
    N|n)
      is_valid=1
      rm_service=0
      ;;
    *)
      echo Please enter [y]es or [n]o
  esac
done

if [ $old_container -eq 1 ] && [ $rm_service -eq 1 ]; then
  printf "\nremoving...\n"
  docker stop ${service_name} && docker rm ${service_name} || printf "\r"
elif [ $old_container -eq 1 ] && [ $rm_service -eq 0 ]; then
  printf "\n Exiting.\n"
  exit 0
fi

docker ps -aq --filter "name=${build_image_name}" | grep -q . && echo another build container already exists, removing... && docker stop $build_image_name && docker rm $build_image_name || printf "\r"

# create bind volumes
printf "\n\e[34mCreating directories on host...\e[39m\n"
for (( i=1; i<"${#paths[@]}"; i+=2 )); do
  if [[ ! -d "$parent_dir/fms-data${paths[$i]}" ]]; then
    mkdir -p -- "$parent_dir/fms-data${paths[$i]}"
  fi
done

printf "\n\e[34mcreating volumes...\e[39m\n"
for (( i=0; i<"${#paths[@]}"; i+=2 )); do
  docker volume create --driver local -o o=bind -o type=none -o device="$parent_dir/fms-data/${paths[$i+1]}" "${paths[$i]}" || {
    printf "error while creating docker volumes"
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
  --tmpfs /tmp \
  --tmpfs /run \
  --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v "${pwd}":/root/build/ \
  -v data-admin-conf:"/opt/FileMaker/FileMaker Server/Admin/conf" \
  -v data-conf:"/opt/FileMaker/FileMaker Server/conf" \
  -v data-data-backups:"/opt/FileMaker/FileMaker Server/Data/Backups" \
  -v data-data-databases:"/opt/FileMaker/FileMaker Server/Data/Databases" \
  -v data-data-preferences:"/opt/FileMaker/FileMaker Server/Data/Preferences" \
  -v data-dbserver-extensions:"/opt/FileMaker/FileMaker Server/Database Server/Extensions/" \
  -v data-http-dotconf:"/opt/FileMaker/FileMaker Server/HTTPServer/.conf" \
  -v data-http-conf:"/opt/FileMaker/FileMaker Server/HTTPServer/conf" \
  -v data-http-logs:"/opt/FileMaker/FileMaker Server/HTTPServer/logs" \
  -v data-Logs:"/opt/FileMaker/FileMaker Server/Logs" \
  -v data-webpub-conf:"/opt/FileMaker/FileMaker Server/Web Publishing/conf" \
  "$base_image" || {
  printf "error while running build container"
  exit 1
}

# run install script inside build container
docker exec -ti $build_image_name /root/build/helper
if [ ! $? ]; then
  printf "error while installing!"
  docker stop $build_image_name
  docker rm $build_image_name
  exit 1
fi

# check for flag file
build_success=$(find . -name build_success)
if [[ ! $build_success ]]; then
  echo "build not successful"
  docker stop $build_image_name
  docker rm $build_image_name
  exit 1
  docker volume rm data-admin-extensions
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

if [[ $start_server -eq 1 ]]; then
  printf "\nDone. Now starting your server ....\n"
  docker-compose up -d $service_name
else
  printf "\nDone. You can now start your server with\e[34m docker-compose up [-d] %s\e[39m\n" "$service_name"
fi
