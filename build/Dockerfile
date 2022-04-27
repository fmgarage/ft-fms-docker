# by Claris
# fmg: added tzdata

FROM ubuntu:18.04

# update all software download sources
RUN DEBIAN_FRONTEND=noninteractive apt-get update

# upgrade all installed software
# packages
RUN DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y

# install filemaker server dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y apache2-bin apache2-utils avahi-daemon curl firewalld fonts-baekmuk fonts-liberation2 fonts-noto fonts-takao fonts-wqy-zenhei libaio1 libavahi-client3 libbz2-1.0 libcurl4 libdjvulibre21 libevent-2.1-6 libexpat1 libfontconfig1 libfreetype6 libgomp1 libicu60 libilmbase12 libjpeg-turbo8 liblqr-1-0 liblzma5 libodbc1 libopenexr22 libpng16-16 libsasl2-2 libtiff5 libuuid1 libvpx5 libwebpdemux2 libwebpmux3 libxml2 libxpm4 libxslt1.1 odbcinst1debian2 openjdk-11-jre openssl policycoreutils sysstat tzdata unzip zip zlib1g

# install user management
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y init

# clean up installations
RUN DEBIAN_FRONTEND=noninteractive apt-get --fix-broken install -y
RUN DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
RUN DEBIAN_FRONTEND=noninteractive apt-get clean -y

# document the ports that should be
# published when filemaker server
# is installed
EXPOSE 80
EXPOSE 443
EXPOSE 2399
EXPOSE 5003

# when containers run, start this
# command as root to initialize
# user management
USER root
CMD ["/sbin/init"]
