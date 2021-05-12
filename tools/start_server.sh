#!/usr/bin/env bash
##!/bin/bash

# go to working dir
pwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
cd "$pwd" || exit 1
parent_dir=$(dirname "${pwd}")

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

# get settings from config
project_id=$(get_setting "ID" ../.env)
check_setting "$project_id"
[ -z "$project_id" ] && {
  printf "error: project ID empty!\nrun setup_project to set an ID.\n"
  exit 1
}

function setup_volumes() {
  # volume-paths array
  paths=(
    "fms-admin-conf-${project_id}" "/Admin/conf/"
    "fms-data-backups-${project_id}" "/Data/Backups/"
    "fms-data-databases-${project_id}" "/Data/Databases/"
    "fms-data-preferences-${project_id}" "/Data/Preferences/"
    "fms-dbserver-extensions-${project_id}" "/Database Server/Extensions/"
    "fms-conf-${project_id}" "/conf/"
    "fms-http-dotconf-${project_id}" "/HTTPServer/.conf/"
    "fms-http-conf-${project_id}" "/HTTPServer/conf/"
    "fms-http-logs-${project_id}" "/HTTPServer/logs/"
    "fms-logs-${project_id}" "/Logs/"
    "fms-webpub-conf-${project_id}" "/Web Publishing/conf/"
  )

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
  if [ "$(find /mnt/wsl/docker-desktop-bind-mounts/${WSL_DISTRO_NAME}/ -maxdepth 1 -type d | wc -l)" -lt 12 ]; then
    setup_volumes
  fi
}

if [ -f /proc/sys/kernel/osrelease ] && grep -q WSL /proc/sys/kernel/osrelease; then
  check_volumes
else
  echo not WSL
fi

volume_count=$(docker volume ls -q --filter="name=${project_id}$")
if [[ $(wc -l <<<"$volume_count") -ne 11 ]]; then # todo get volume count from path array
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
