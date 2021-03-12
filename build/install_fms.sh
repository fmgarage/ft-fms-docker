#!/usr/bin/env bash


build_dir_mount=/root/build/
# rpm_name=filemaker_server-19.1.2-234.x86_64.rpm
# rpm_name=filemaker_server-19.2.1-23.x86_64.rpm
# rpm_name=fms-linux-912.rpm
rpm_name=fms-linux-921.rpm
url=$(cat url.txt)
package_url=$url$rpm_name
package_remove=false
assisted_install=assisted_install.txt


# install CentOS SCLo RH repository for httpd24
yum install centos-release-scl -y
# yum install centos-release-scl-rh -y

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

# remove install packages
rm -rv /root/deps/
if [[ $package_remove ]]; then
    rm -rv ${build_dir_mount}${rpm_name}
fi

# OR exit
exit
