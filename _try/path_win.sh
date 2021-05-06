#!/usr/bin/env bash

# is WSL?
wsl=$(env | grep WSL )
if [ -n "$wsl" ]; then
  echo wslpath -u pwd
  exit 1
fi

# go to working dir
#pwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit
#cd "$pwd" || exit
#parent_dir=$(dirname "${pwd}")
