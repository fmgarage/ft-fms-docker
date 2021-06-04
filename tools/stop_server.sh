#!/usr/bin/env bash
##!/bin/bash

# go to working dir
pwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
cd "$pwd" || exit 1
parent_dir=$(dirname "${pwd}")

# Load Variables
source ../common/settings.sh

## stop that nasty service
#printf "\nNow stopping httpd service ....\n"
#docker exec fms-${project_id} touch "/opt/FileMaker/FileMaker Server/HTTPServer/stop" || {
#  printf "error while stopping httpd service\n"
#  exit 1
#}

printf "\nDone. Now stopping your server ....\n"
docker stop fms-${project_id} || {
  printf "error while stopping fms container\n"
  exit 1
}

printf "\ndone\n"
exit 0
