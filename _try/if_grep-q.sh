#!/bin/bash

function check_volumes() {
  printf "WSL linux, checking bind volumes...\n"
  find /mnt/wsl/docker-desktop-bind-mounts/${WSL_DISTRO_NAME}/ -maxdepth 1 -type d | wc -l
}

if [ -f /proc/sys/kernel/osrelease ] && grep -q WSL /proc/sys/kernel/osrelease; then
  check_volumes
else
  echo not WSL
fi
