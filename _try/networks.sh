#!/bin/bash

start_server=1
# check if fms network exists
network=0
docker network ls -q --filter "name=fms-net" | grep -q . && network=1  # || network=0
case $network in
0)
  echo "Network fms-net not found, will be created"
  compose_files="-f docker-compose.yml -f fms-network.yml"
  ;;
1)
  compose_files="-f docker-compose.yml"
  ;;
*)
  printf "error while looking for fms docker network: %s" "$(docker network ls -q --filter "name=fms-net")"
  exit 1
  ;;
esac

if [[ $start_server -eq 1 ]]; then
  printf "\nDone. Now starting your server ....\n"

  docker-compose $compose_files up -d fms
else
  printf "\nDone. You can now start your server with\e[36m docker-compose %s up [-d] %s\e[39m\n" "$compose_files" "service_name"
fi