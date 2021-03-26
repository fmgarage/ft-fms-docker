#!/usr/bin/env bash


# go to working dir
pwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )"  && pwd )" || exit
cd "$pwd" || exit

# image name according
cert_prefix=$(grep "cert_prefix=" ./config.txt | sed 's/.*=//')
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
    url=$(grep "url=" ./config.txt | sed 's/.*=//')
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
docker run -d --name $build_image_name --cap-add=SYS_ADMIN --tmpfs /tmp --tmpfs /run --tmpfs /run/lock -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v "${pwd}":/root/build/ "$base_image"

# run install script in build container
docker exec -ti $build_image_name /root/build/install_fms.sh

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
