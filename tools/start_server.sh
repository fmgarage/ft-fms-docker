#!/usr/bin/env bash
##!/bin/bash

# go to working dir
pwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
cd "$pwd" || exit 1
parent_dir=$(dirname "${pwd}")

# Load Variables
source ../common/settings.sh
source ../common/paths.sh

[ -z "$project_id" ] && {
  printf "error: project ID empty!\nrun setup_project to set an ID.\n"
  exit 1
}

function setup_volumes() {

  # check directories
  printf "\n\e[36mChecking directories on host...\e[39m\n"
  for ((i = 1; i < "${#paths[@]}"; i += 2)); do
    if [[ ! -d "$parent_dir/fms-data${paths[$i]}" ]]; then
      printf "Directories in fms-data do not exist!" >&2
      exit 1
    fi
  done

  # create bind volumes
  printf "\n\e[36mcreating volumes...\e[39m\n"
  for ((i = 0; i < "${#paths[@]}"; i += 2)); do
    docker volume create --driver local -o o=bind -o type=none -o device="$parent_dir/fms-data${paths[$i + 1]}" "${paths[$i]}" || {
      printf "error while creating docker volumes" >&2
      exit 1
    }
  done

  printf "\nVolumes are setup.\n"
  #  exit 0

}

# check volumes
function check_volumes() {
  printf "WSL linux, checking bind volumes...\n"
  if [ "$(find /mnt/wsl/docker-desktop-bind-mounts/${WSL_DISTRO_NAME}/ -maxdepth 1 -type d | wc -l)" -lt 13 ]; then
    setup_volumes
  fi
}

if [ -f /proc/sys/kernel/osrelease ] && grep -q WSL /proc/sys/kernel/osrelease; then
  check_volumes
else
  echo not WSL
fi

volume_count=$(docker volume ls -q --filter="name=${project_id}$")
volume_count_goal=$(expr ${#paths[@]} / 2)
if [[ $(wc -l <<<"$volume_count") -ne $volume_count_goal ]]; then
  echo "setting up volumes"
  setup_volumes
fi

# check for docker network fms-net
network=0
docker network ls -q --filter "name=^fms-net$" | grep -q . && network=1
case $network in
0)
  echo "Network fms-net not found, will be created"
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

printf "\nDone. Now starting your server ....\n"
docker-compose $compose_files up -d fms || {
  printf "error while starting fms container\n"
  exit 1
}

printf "\ndone\n"
exit 0
