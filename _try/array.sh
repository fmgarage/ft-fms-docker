#!/usr/bin/env bash

# go to working dir
pwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit
cd "$pwd" || exit
parent_dir=$(dirname "${pwd}")

# associative
declare -A paths
# indexed
declare -a volumes

paths["data-admin-conf"]="/Admin/conf/"
paths["data-data-databases"]="/Data/Databases/"
paths["data-data-preferences"]="/Data/Preferences/"
paths["data-dbserver-extensions"]="/Database Server/Extensions/"
paths["data-conf"]="/conf/"
paths["data-http-dotconf"]="/HTTPServer/.conf/"
paths["data-http-conf"]="/HTTPServer/conf/"
paths["data-http-logs"]="/HTTPServer/logs/"
paths["data-logs"]="/Logs/"
paths["data-webpub-conf"]="/Web Publishing/conf/"

#paths=(
#  "/Admin/conf/"
#  "/Data/Databases/"
#  "/Data/Preferences/"
#  "/Database Server/Extensions/"
#  "/conf/"
#  "/HTTPServer/.conf/"
#  "/HTTPServer/conf/"
#  "/HTTPServer/logs/"
#  "/Logs/"
#  "/Web Publishing/conf/"
#)

# create bind volumes
printf "\n\e[36mCreating directories on host...\e[39m\n"
for vol in "${!paths[@]}"; do
  printf "%s ++ %s\n" "$vol" "${paths[$vol]}"
  #  printf "%s\n" "${path}"
  #  if [[ ! -d "$parent_dir/fms-data$path" ]]; then
  #    mkdir -p -- "$parent_dir/fms-data$path"
  #  fi
  #  if [[ ! -d "$parent_dir/fms-data${path}" ]]; then
  #    mkdir -p -- "$parent_dir/fms-data${path}"
  #  fi
done

#printf "\n\e[36m...\e[39m\n"
#ls -lah
