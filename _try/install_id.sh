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

# set project id
# todo wording
#while [ $is_valid -eq 0 ] && [ $old_container -eq 1 ]; do
  printf "Do you want to enter a project name [y] or do you want an automatic ID assigned to this instance [n] ? [y/n]"
  read -r user_input

  case $user_input in
  Y | y)
    printf "Enter project name:\n"
    read -r project_id
    # todo while valid (check if exists)
    ;;
  N | n)
    # todo while valid (check if exists)
    project_id=$(uuidgen | md5)
    echo "$project_id"
    ;;
  *)
    echo Please enter [y]es or [n]o
    ;;
  esac
#done
# todo write to .env
echo "ID=${project_id}" > ../.env

# todo set volume names, service

# volume-paths array
paths=(
  "fms-admin-conf-${project_id}" "/Admin/conf/"
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
  service_name=fms-${project_id}
else
  image_name=centos-fms-c-19_2
  service_name=fms-c--${project_id}
fi

build_image_name=fmsinstall
# todo pin version tag / digest
base_image=jrei/systemd-centos:7
date=$(date +%Y-%m-%d)


printf "%s\n" "$service_name"
printf "%s\n" "$paths"
