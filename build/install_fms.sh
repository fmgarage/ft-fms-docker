#!/usr/bin/env bash


build_dir_mount=/root/build/
# rpm_name=filemaker_server-19.1.2-234.x86_64.rpm
# rpm_name=filemaker_server-19.2.1-23.x86_64.rpm
# rpm_name=fms-linux-912.rpm
rpm_name=fms-linux-921.rpm
url=$(cat ${build_dir_mount}url.txt)
package_url=$url$rpm_name
package_remove=false
assisted_install=assisted_install.txt
fms_admin_user=$(grep "Admin Console User=" ${build_dir_mount}assisted_install.txt | sed 's/.*=//')
fms_admin_pass=$(grep "Admin Console Password=" ${build_dir_mount}assisted_install.txt | sed 's/.*=//')
cert_prefix=$(cat ${build_dir_mount}cert_prefix.txt)

# color prompt global
echo "PS1='\[\033[02;32m\]\u@\H:\[\033[02;34m\]\w\$\[\033[00m\] '" >> /etc/bashrc

# install CentOS SCLo RH repository for httpd24
yum install centos-release-scl -y
# yum install centos-release-scl-rh -y

# update
yum update -y

# pre packages, possibly omit sudo, autofs
yum install bash-completion NetworkManager firewalld nano policycoreutils net-tools httpd24 httpd24-mod_ssl -y

# download filemaker_server package
if [[ ! -f "${build_dir_mount}""${rpm_name}" ]]; then
    printf "\ndownloading fms package ...\n"
    package_remove=true
    curl "${package_url}" --output ${build_dir_mount}${rpm_name}
fi

# preload dependencies
yum install --downloadonly --downloaddir=/root/deps ${build_dir_mount}${rpm_name} -y

# preinstall dependencies
yum install root/deps/* -y

# install filemaker_server
FM_ASSISTED_INSTALL="${build_dir_mount}""${assisted_install}" yum install "${build_dir_mount}""${rpm_name}" -y

# check
systemctl

# import cert
printf "\nimport certificate\n"
fmsadmin certificate import -yu "${fms_admin_user}" -p "${fms_admin_pass}" --keyfile ${build_dir_mount}"${cert_prefix}".key --intermediateCA ${build_dir_mount}"${cert_prefix}".ca-bundle ${build_dir_mount}"${cert_prefix}".crt

# remove install packages
printf "\nremove install packages\n"
rm -rv /root/deps/
if [[ $package_remove ]]; then
    rm -r ${build_dir_mount}${rpm_name}
fi

# OR exit
exit
