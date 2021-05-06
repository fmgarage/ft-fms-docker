#!/usr/bin/env bash

# go to working dir
pwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit
cd "$pwd" || exit
parent_dir=$(dirname "${pwd}")

# paths
paths=(
  "/Database Server/Extensions/"
  "/Data/Databases/"
  "/Data/Preferences/"
  "/Admin/conf/"
  "/conf/"
  "/HTTPServer/.conf/"
  "/HTTPServer/conf/"
  "/HTTPServer/logs/"
  "/Logs/"
  "/Web Publishing/conf/"
)

# create bind volumes
printf "\n\e[36mCreating directories on host...\e[39m\n"
for path in "${paths[@]}"; do
  echo "$path"
#  printf "%s\n" "${path}"
  if [[ ! -d "$parent_dir/fms-data$path" ]]; then
    mkdir -p -- "$parent_dir/fms-data$path"
  fi
#  if [[ ! -d "$parent_dir/fms-data${path}" ]]; then
#    mkdir -p -- "$parent_dir/fms-data${path}"
#  fi
done

printf "\n\e[36m...\e[39m\n"
ls -lah
