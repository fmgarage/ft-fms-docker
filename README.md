# fmg-dockerfms
Run FileMaker Server for Linux in Docker

Scripts to automatically build a ready-to-run Docker image.

edit `./build/config.txt`
run: `./build/install.sh`

requires:
- assisted install file - for headless setup
- SSL/TLS certificates (optional)
- config.txt - your certificates (optional), fms package download URL (optional), name of assisted install file

#### todo:

- Database Folder
- unset ENVs
