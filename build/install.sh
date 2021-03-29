#!/usr/bin/env bash



# go to working dir
pwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )"  && pwd )" || exit
cd "$pwd" || exit

# parse config
function get_setting {
    grep -Ev '^\s*$|^\s*\#' "$2" | grep -E "\s*$1\s*=" | sed 's/.*=//; s/ //g'
}

function check_setting {
    if [[ $(wc -l <<< "$1") -gt 1 ]]; then
        echo "multiple values found, 1 expected" >&2
        exit 1
    fi
}
# debug
echo settings...

# get settings from config
# debug
echo settings cert...
cert_prefix=$(get_setting "cert_prefix" ./config.txt)
check_setting "$cert_prefix"

# debug
echo settings assist...
assisted_install=$(get_setting "assisted_install" ./config.txt)
check_setting "$assisted_install"
# debug
echo settings assisted_install...

admin_user=$(get_setting "Admin Console User" ./"$assisted_install")
admin_pass=$(get_setting "Admin Console Password" ./"$assisted_install")


if [[ ! $cert_prefix ]]; then
    image_name=centos-fms-19_2
else
    image_name=centos-fms-c-19_2
fi

build_image_name=fmsinstall
# todo pin version tag or is 7 sufficient?
base_image=jrei/systemd-centos:7
date=$(date +%Y-%m-%d)

# check install package
# download filemaker_server package
package=$(find . -name "*.rpm")
plines=$(wc -l <<< "$package" )
if [[ ! $package ]]; then
    printf "\ndownloading fms package ...\n"
    url=$(get_setting "url")
        STATUS=$(curl -s --head --output /dev/null -w '%{http_code}' "$url")
        if [ ! $STATUS -eq 200 ]; then
            echo "Got a $STATUS from $url ..."
            exit
        fi
    curl "${url}" -O || exit
    echo "" > ./package_remove
    # package=$(find . -name "*.rpm")
elif [[ $plines -gt 1 ]]; then
    printf "%s rpm packages found, 1 expected" "$plines"
    exit 1
fi


# check if container names are in use
docker ps -aq --filter "name=${build_image_name}" | grep -q . && echo another build container already exists, removing... && docker stop $build_image_name && docker rm $build_image_name || printf "\r"
docker ps -aq --filter "name=fmserver" | grep -q . && echo another fmserver container already exists, removing... && docker stop fmserver && docker rm fmserver || printf "\r"


# build container
docker run -d \
    --name $build_image_name \
    --cap-add=SYS_ADMIN \
    -e CERT_PREFIX="$cert_prefix" \
    -e PACKAGE_REMOVE="$package_remove" \
    -e ASSISTED_INSTALL="$assisted_install" \
    -e FMS_ADMIN_USER="$admin_user" \
    -e FMS_ADMIN_PASS="$admin_pass" \
    --tmpfs /tmp \
    --tmpfs /run \
    --tmpfs /run/lock \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -v "${pwd}":/root/build/ "$base_image"

# run install script in build container
docker exec -ti $build_image_name /root/build/helper
# docker exec -ti $build_image_name /root/build/install_fms.sh

# check for flag file
build_success=$(find . -name build_success)
if [[ ! $build_success ]]; then
    echo "build not successful"
    exit 1
fi

# remove flag file
rm "$build_success" || exit 1

# docker commit
printf "\ncommit build container to new image ...\n"
docker commit -c "EXPOSE 80" -c "EXPOSE 443" -c "EXPOSE 2399" -c "EXPOSE 5003" -c "EXPOSE 16000-16002" "${build_image_name}" "${image_name}":"${date}"
docker tag $image_name:"${date}" "${image_name}":latest

# remove $build...
printf "\nremoving build container ...\n"
docker stop $build_image_name && docker rm $build_image_name

printf "\nDone. You can now start your server with \e[34mdocker-compose up [-d] fms\e[39m or \e[34mfms-c\e[39m if you installed certificates.\n"
