#!/usr/bin/env bash
##!/bin/bash

# todo check if root

# go to working dir
pwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
cd "$pwd" || exit 1
parent_dir=$(dirname "${pwd}")
inside_base_path="/opt/FileMaker/FileMaker Server/"

# volume-paths array
paths=(
  "fms-admin-conf" "/Admin/conf/"
  "fms-data-backups" "/Data/Backups/"
  "fms-data-databases" "/Data/Databases/"
  "fms-data-preferences" "/Data/Preferences/"
  "fms-dbserver-extensions" "/Database Server/Extensions/"
  "fms-conf" "/conf/"
  "fms-http-dotconf" "/HTTPServer/.conf/"
  "fms-http-conf" "/HTTPServer/conf/"
  "fms-http-logs" "/HTTPServer/logs/"
  "fms-logs" "/Logs/"
  "fms-webpub-conf" "/Web Publishing/conf/"
)

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

# set instance id
# todo wording
#while [ $is_valid -eq 0 ] && [ $old_container -eq 1 ]; do
  printf "Please enter a name or leave empty for an automatic ID to be assigned to this instance: "
  read -r user_input

  case $user_input in
  "")
    # todo while valid (check if exists)
    instance_id=$(uuidgen | md5-sum "$@" | cut -c-12)
    echo "id: " "$instance_id"
    ;;
  (*[!abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_.-]*)
    echo >&2 "That ID is not allowed. Please use only characters [a-zA-Z0-9_.-]"
    exit 1
    ;;
  *)
    instance_id=$user_input
    # todo while valid (check if exists)
    ;;
  esac

#done
# todo write to .env
echo "ID=${instance_id}" > ../.env

# todo set volume names, service

# volume-paths array
paths=(
  "fms-admin-conf-${instance_id}" "/Admin/conf/"
  "fms-data-backups" "/Data/Backups/"
  "fms-data-databases" "/Data/Databases/"
  "fms-data-preferences" "/Data/Preferences/"
  "fms-dbserver-extensions" "/Database Server/Extensions/"
  "fms-conf" "/conf/"
  "fms-http-dotconf" "/HTTPServer/.conf/"
  "fms-http-conf" "/HTTPServer/conf/"
  "fms-http-logs" "/HTTPServer/logs/"
  "fms-logs" "/Logs/"
  "fms-webpub-conf" "/Web Publishing/conf/"
)


if [[ ! $c_cert ]] || [[ ! $c_bundle ]] || [[ ! $c_key ]]; then
  image_name=centos-fms-19_2
  service_name=fms-${instance_id}
else
  image_name=centos-fms-c-19_2
  service_name=fms-c--${instance_id}
fi

build_image_name=fmsinstall
# todo pin version tag / digest
base_image=jrei/systemd-centos:7
date=$(date +%Y-%m-%d)


printf "%s\n" "$service_name"
printf "%s\n" "$paths"
