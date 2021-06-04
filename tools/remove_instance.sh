#!/usr/bin/env bash
##!/bin/bash

# go to working dir
pwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
cd "$pwd" || exit 1

# Load Variables
source ../common/get_instance_id.sh

# remove container
container_name=fms-${instance_id}
old_container=0
running=0
rm_container=0
docker ps -aq --filter "name=${container_name}" | grep -q . && old_container=1
docker ps -q --filter "name=${container_name}" | grep -q . && running=1
is_valid=0
while [ $is_valid -eq 0 ] && [ $old_container -eq 1 ]; do
  echo Remove "${container_name}" container and attached volumes? [y/n]
  read -r remove_container

  case $remove_container in
  Y | y)

    is_valid=1
    rm_container=1
    ;;
  N | n)
    is_valid=1
    rm_container=0
    ;;
  *)
    echo Please enter [y]es or [n]o
    ;;
  esac
done

if [ $old_container -eq 1 ] && [ $rm_container -eq 1 ]; then
  printf "\nstopping...\n" &&
  docker stop ${container_name} &&
  printf "\nremoving...\n" &&
  docker rm ${container_name} || printf "\r"
elif [ $old_container -eq 1 ] && [ $rm_container -eq 0 ]; then
  printf "\nExiting.\n"
  exit 2
else
  printf "no container found\n"
fi

# remove bind volumes
printf "\n\e[36mremoving docker volumes...\e[39m\n"

docker volume rm $(docker volume ls -q --filter="name=${instance_id}$")

#for ((i = 0; i < "${#paths[@]}"; i += 2)); do
#  docker volume rm "${paths[$i]}" || {
#    printf "error while removing docker volumes"
#    exit 1
#  }
#done

printf "\nDone!\n"
exit 0
