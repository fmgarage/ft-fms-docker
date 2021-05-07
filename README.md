# fmg-dockerfms
Run FileMaker Server for Linux in Docker Desktop for Mac or Windows. Everything you need to automatically build a ready-to-run Docker image.

**Windows**: there are currently some issues (see below). 

We are constantly improving the scripts and try to get rid of the remaining issues. If you want to stay up-to-date, make sure to watch the repo and maybe follow us on Twitter: [@fmgarage](https://twitter.com/fmgarage)




## Installation on macOS



### Docker Desktop

Download and install the latest version of Docker Desktop.



### Repo

Clone or download the repo and move it to your documents folder. You may rename it to something like

```shell
~/Documents/FMS-Linux
```



### FileMaker Server

Download a copy of the FileMaker Server installer for Linux from your Claris account page, unpack the zip file and move the Red Hat Package Manager (rpm) file to the build folder in the repo. You can also put a  link into the config.txt, the installer will be downloaded instead then. 

With the current version of the installer it will look like this:

```shell
~/Documents/FMS-Linux/build/filemaker_server-19.2.1-23.x86_64.rpm
```

You can adjust the settings in the *Assisted Install.txt* file, but you don't need to. The server admin console login will be admin/admin then, which can be changed later.



### SSL Certificate

If you have a certificate that you might want to use for this server, simply copy the files (key, cert and intermediate) into the *build* directory, the installer will automatically look for the appropriate file endings (.pem, .crt and .ca-bundle). If you don' t provide any, the server will use the default self-signed certificate instead. 



### Build Image and run Container

FileMaker Server requires port 5003 to start, so make sure to quit any FileMaker Pro client before proceeding.

Open Terminal.app, drag the **install.sh** into the terminal window, hit return and give your server instance a name. Or just let it be tagged with an ID.

After the installation process is finished, check the Dashboard in Docker Desktop, there should be a running container named **fms-[name-tag]**.

Open the admin console by clicking the *Open in Browser* button in the container actions. In case you installed without certificate you will have to confirm the self-signed one.

- Chrome: doesn't work with no valid certificate
- Safari: possible to bypass the certificate warning
- Edge: possible to bypass the certificate warning, but opened from Docker Dashboard, the URL comes as an `http` link, and you need to append `https://`.

Clicking the CLI button will open a terminal window where you can use the fmsadmin command to control your server.



## Installation on Windows 10

**Important**: As of now it is not possible to run both FileMaker Server (in Docker) and FileMaker Pro at the same time on a Windows machine. FileMaker Pro also binds port 5003 on launch and it is not possible to make a connection to the local server. 

In addition to the macOS instructions you will have to install the Windows Subsystem for Linux **WSL** first. To do so, follow these instructions: https://docs.microsoft.com/de-de/windows/wsl/install-win10 ("Manual Installation Steps").

Download and install Ubuntu from the Windows Store (Ubuntu and Ubuntu 20.04 apps are identical), just make sure it is the one offered by Canonical Group Limited.
When installed, update packages:
```shell
sudo apt update
sudo apt upgrade
```

Most likely, it will be necessary to restart Ubuntu after the update, which in this case is done by leaving the linux environment with
```shell
exit
```
and then starting Ubuntu again.

Now, to provide the necessary systemd service to the Ubuntu host, run this script:
https://github.com/damionGans/ubuntu-wsl2-systemd-script

Again, restart Ubuntu by exiting and starting again.


In the Docker Desktop settings: Under **General**, activate WSL2 based engine and under **Resources > WSL Integration** activate WSL2 support for your Ubuntu installation.
It may be necessary to restart both Docker Desktop and Ubuntu (or even reboot Windows) to get the integration into a working state. You can test and see if `docker ps` from the Ubuntu terminal throws any error.

Since it is recommended not to mount volumes from the Windows filesystem into a WSL2 Docker container but rather directly from the WSL filesystem , copy the installer into the Linux filesystem, assuming you put the installer into Documents:

```
sudo cp -rv /mnt/c/Users/your_windows_username/Documents/fmg-dockerfms-main ~/fms
```

It may be necessary to grant an access rule for Docker Desktop in the **Windows firewall** when prompted. 

Run the installer :
```
./fms/build/install.sh
```

[comment]: <> (ggf. erneut installieren bei Fehler)
[comment]: <> (- fmsadmin permissions)


The Linux filesystem can also be mounted as network volume into the Windows Explorer by using a path like:
```
\\wsl$\your_linux_distro\
```
But, due to permissions, this isn't of much use apart from reading files.



#### Issues: 

Folders (for databases, backups…) are created on container start but not reconnected if you reboot and start Docker Desktop again. Existing files will not be overwritten, but new volumes must be created and attached to the local folders.
This happens in the `start_server` script, where the wsl directory is checked before starting the container. It is considered a workaround to this issue: [docker/for-win/issues/10060](https://github.com/docker/for-win/issues/10060)

Sometimes when stopping the server container with `tools/stop_server`, the fmshelper process doesn't exit. We're still figuring out why.
The StopTimeout for the container is 10 minutes, after that it will be stopped forcefully. You can take a shortcut with `docker stop fms-[name-tag] -t 5` (stop with timeout 5 seconds).

Docker Desktop for Windows fails to restart, rebooting Windows may be the fastest way solve this. 



## Tools

To handle some issues and restrictions, there are scripts for controlling your server instances in the `tools/` subdirectory:



**setup_project**

Lets you set a project name or ID and creates bind volumes. Also looks for fms-data directories.

**remove_project**

Removes bind volumes and container, but not the fms-data directory. Delete project directory by hand.

**start_server**

Start this server instance.

**stop_server**

Stops server, you will be prompted to close any open databases.
(Sometimes doesn't work on Windows, see issues.)

**global_cleanup**

This removes any dangling volumes (attached to no container) and also removes the docker network `fms-net`, when no container named `fms-*` is left.

### 


## Administration


### Stopping and Restarting the Server

At the moment, quitting Docker Desktop will not gracefully close your databases or stop the server. To prevent your databases from being corrupted by the hard shutdown, always stop the container with `tools/stop_server` or use the *fmsadmin stop server* command beforehand.



### Accessing files

Relevant directories are being mounted into the container as volumes. These volumes are bound to their corresponding folders on the host in the `fms-data` folder. In case the container is removed, it is possible to run a new container with the persisted state with the `tools/start_server` script. It is recommended not to edit these files while the server is running.

The directories include databases, logs, configs and extensions.



### Managing Instances 

(macOS only) 

If you need more than one instance, you can simply duplicate an installation (will also duplicate settings, logs and databases, setup new project name with `tools/setup_project`)

It is possible to have multiple instances of these installations, but you can run only one at a time. Each installation is bound to its directory, where the `fms-data` (FileMaker Server directories) directory and the `.env` (name-tag) file are located. 



### Snapshots

(macOS only)

As all settings and database files are stored in the fma-data folder, you can



## More Technical Stuff



### config.txt

(was kann man alles einstellen)



#### Linux on Windows

The Linux distro used for running the installer and then the container needs systemd, which is not yet officially supported in WSL2. Still, it's possible  (as of now, for Ubuntu) with the following script:
https://github.com/damionGans/ubuntu-wsl2-systemd-script