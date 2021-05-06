#!/bin/bash

# volume-paths array
paths=( \
  "data-admin-conf" "/Admin/conf/" \
  "data-data-backups" "/Data/Backups/" \
  "data-data-databases" "/Data/Databases/" \
  "data-data-preferences" "/Data/Preferences/" \
  "data-dbserver-extensions" "/Database Server/Extensions/"
  "data-conf" "/conf/" \
  "data-http-dotconf" "/HTTPServer/.conf/"
  "data-http-conf" "/HTTPServer/conf/" \
  "data-http-logs" "/HTTPServer/logs/"
  "data-logs" "/Logs/" \
  "data-webpub-conf" "/Web Publishing/conf/"
)

# create bind volumes
printf "\n\e[36mCreating directories on host...\e[39m\n"

for (( i=0; i<"${#paths[@]}"; i+=2 )); do
    printf "%s -- %s\n" "${paths[$i]}" "${paths[$i+1]}"
done
