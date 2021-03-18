# fmg-dockerfms
Run FileMaker Server for Linux in Docker

Scripts to automatically build a ready-to-run Docker image

run: `./build/make_image.sh`

requires:
- assisted_install file - for headless setup
- SSL/TLS certificates
- config.txt - naming of your certificates, fms package download URL, name of assisted install file

#### todo:

- Database Folder