#!/usr/bin/env bash


printf "\n  --  \e[36mStarting install inside test container\e[39m\n"
# settings
build_dir_mount=/root/build/


# color prompt global
echo "PS1='\[\033[02;32m\]\u@\H:\[\033[02;34m\]\w\$\[\033[00m\] '" >> /etc/bashrc


echo "" > ${build_dir_mount}build_success

#   debug
printf "\n  PERMISSIONS oO"
printf "\n%s" "$(id)"
printf "\n%s" "$(ls -lahn $build_dir_mount)"


printf "\n  --  \e[36mFinished install inside test container, returning...\e[39m\n"

# exit
exit 0
