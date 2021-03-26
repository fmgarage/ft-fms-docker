#!/usr/bin/env bash

# settings
build_dir_mount=/root/build/
# url=$(grep "url=" ${build_dir_mount}config.txt | sed 's/.*=//')
cert_prefix=$(grep "cert_prefix=" ${build_dir_mount}config.txt | sed 's/.*=//')
# package_url=$url
package_remove=$(find "$build_dir_mount" -name package_remove)
assisted_install=$(grep "assisted_install=" ${build_dir_mount}config.txt | sed 's/.*=//')
fms_admin_user=$(grep "Admin Console User=" ${build_dir_mount}"${assisted_install}" | sed 's/.*=//')
fms_admin_pass=$(grep "Admin Console Password=" ${build_dir_mount}"${assisted_install}" | sed 's/.*=//')

# color prompt global
echo "PS1='\[\033[02;32m\]\u@\H:\[\033[02;34m\]\w\$\[\033[00m\] '" >> /etc/bashrc

# install CentOS SCLo repository for httpd24
yum install centos-release-scl -y || exit 1

# update
yum update -y

# pre packages, possibly omit sudo, autofs
yum install bash-completion firewalld nano policycoreutils net-tools httpd24 httpd24-mod_ssl -y || exit 1

# download filemaker_server package
package=$(find "$build_dir_mount" -name "*.rpm")
if [[ ! $package ]]; then
    printf "no rpm package found"
    exit 1
fi

# preload dependencies
yum install --downloadonly --downloaddir=/root/deps "${package}" -y || exit 1

# preinstall dependencies
yum install root/deps/* -y

# install filemaker_server
FM_ASSISTED_INSTALL="${build_dir_mount}""${assisted_install}" yum install "${package}" -y || exit 1

# check
systemctl

# import cert
if [[ $cert_prefix ]]; then
    printf "\nimport certificate\n"
    fmsadmin certificate import -yu "${fms_admin_user}" -p "${fms_admin_pass}" --keyfile ${build_dir_mount}"${cert_prefix}".key --intermediateCA ${build_dir_mount}"${cert_prefix}".ca-bundle ${build_dir_mount}"${cert_prefix}".crt
fi

# remove install packages
printf "\nremove install packages\n"
rm -r /root/deps/
if [[ $package_remove ]]; then
    printf "\nremove fms package\n"
    rm -r "${package}" "$package_remove"
fi

echo "" > ${build_dir_mount}build_success
# exit
exit 0
