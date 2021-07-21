#!/usr/bin/env bash

# credit: https://unix.stackexchange.com/a/451925
# get timezone from host

function get_tz() {
  set -euo pipefail
  if filename=$(readlink /etc/localtime); then
      # /etc/localtime is a symlink as expected
      timezone=${filename#*zoneinfo/}
      if [[ $timezone = "$filename" || ! $timezone =~ ^[^/]+/[^/]+$ ]]; then
          # not pointing to expected location or not Region/City
          >&2 echo "$filename points to an unexpected location"
          exit 1
      fi
      echo "$timezone"
  else  # compare files by contents
      # https://stackoverflow.com/questions/12521114/getting-the-canonical-time-zone-name-in-shell-script#comment88637393_12523283
      find /usr/share/zoneinfo -type f ! -regex ".*/Etc/.*" -exec \
          cmp -s {} /etc/localtime \; -print | sed -e 's@.*/zoneinfo/@@' | head -n1
  fi
}
