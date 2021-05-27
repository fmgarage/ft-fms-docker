#!/usr/bin/env bash

printf "\n  --  \e[36mStarting install inside fmsinstall container\e[39m\n"

# settings
build_dir_mount=/root/build/

c_cert=$CERT_CERT
c_bundle=$CERT_BUNDLE
c_key=$CERT_KEY

assisted_install=$ASSISTED_INSTALL
fms_admin_user=$FMS_ADMIN_USER
fms_admin_pass=$FMS_ADMIN_PASS
package_remove=$PACKAGE_REMOVE

# unset envs
unset CERT_CERT CERT_BUNDLE CERT_KEY ASSISTED_INSTALL FMS_ADMIN_USER FMS_ADMIN_PASS PACKAGE_REMOVE || exit 1

# color prompt global
echo "PS1='\[\033[02;32m\]\u@\H:\[\033[02;34m\]\w\$\[\033[00m\] '" >>/etc/bashrc

# update
apt update && apt upgrade -y

# pre packages, possibly omit sudo, autofs
apt install bash-completion nano net-tools apt-utils ubuntu-advantage-tools acl -y || {
  printf "error while installing pre-packages\n"
  exit 1
}

# download filemaker_server package
package=$(find "$build_dir_mount" -name "*.deb")
if [[ ! $package ]]; then
  printf "no deb package found\n"
  exit 1
fi

# install filemaker_server
FM_ASSISTED_INSTALL="${build_dir_mount}""${assisted_install}" apt install "${package}" -y || {
  echo "error while installing filemaker server"
  exit 1
}

# check
systemctl --no-pager || {
  printf "error while systemctl\n"
  exit 1
}

# import cert
if [[ $c_cert ]] && [[ $c_bundle ]] && [[ $c_key ]]; then
  printf "\nimport certificate\n"
  fmsadmin certificate import -yu "${fms_admin_user}" -p "${fms_admin_pass}" --keyfile ${build_dir_mount}"${c_key}" --intermediateCA ${build_dir_mount}"${c_bundle}" ${build_dir_mount}"${c_cert}" || {
    printf "error while installing certificates\n"
    exit 1
  }
fi

# default fms config
printf "\n  --  \e[36mdefault fmsadmin settings... \e[39m\n"
fmsadmin -u "$fms_admin_user" -p "$fms_admin_pass" set serverconfig SecureFilesOnly=false || {
  printf "error while fmsadmin securefilesonly\n"
  exit 1
}
fmsadmin -u "$fms_admin_user" -p "$fms_admin_pass" -y disable schedule 1 || {
  printf "error while fmsadmin disable schedule\n"
  exit 1
}

## change systemd unit stop timeout
#mkdir -p /etc/systemd/system/fmshelper.service.d/
#cat >/etc/systemd/system/fmshelper.service.d/override.conf <<EOF
#[Service]
#TimeoutStopSec=10m
#EOF

# increase stop timeout to be able close files automatically
sed -i 's/timeout=20/timeout=60/g'  /opt/FileMaker/etc/init.d/fmshelper || {
  printf "error while changing fmshelper script\n"
  exit 1
}

touch ${build_dir_mount}build_success && chown 1000:1000 ${build_dir_mount}build_success

printf "\n  --  \e[36mFinished install inside fmsinstall container, returning...\e[39m\n"

# exit
exit 0
