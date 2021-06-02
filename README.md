# fmg-dockerfms
Run FileMaker Server for Linux in Docker Desktop for Mac or Windows. Everything you need to automatically build a ready-to-run Docker image.

**Windows**: there are currently some issues (see below). 

We are constantly improving the scripts and try to get rid of the remaining issues. If you want to stay up-to-date, make sure to watch the repo and maybe follow us on Twitter: [@fmgarage](https://twitter.com/fmgarage)

- [Installation on macOS](#installation-on-macos)

- [Installation on Windows 10](#installation-on-windows-10)

- [Tools](#tools)

- [Administration](#administration)

## Installation on macOS



#### Docker Desktop

Download and install the latest version of Docker Desktop.



#### Repo

Clone or download the repo and move it to your documents folder. You may rename it to something like

```shell
~/Documents/FMS-Linux
```



#### FileMaker Server

Download a copy of the FileMaker Server installer for Linux from your Claris account page, unpack the zip file and move the Red Hat Package Manager (rpm) file to the build folder in the repo. You can also put a link into the config.txt instead, the installer will be downloaded then.

With the current version of the installer it will look like this:

```shell
~/Documents/FMS-Linux/build/filemaker_server-19.2.1-23.x86_64.rpm
```

You can adjust the settings in the *Assisted Install.txt* file, but you don't need to. The server admin console login will be admin/admin then, which can be changed later.



#### SSL Certificate

If you have a certificate that you might want to use for this server, simply copy the files (key, cert and intermediate) into the *build* directory, the installer will automatically look for the appropriate file endings (.pem, .crt and .ca-bundle). If you don' t provide any, you can install them later or select the default self-signed certificate on first admin console launch.



#### Build Image and run Container

FileMaker Server requires port 5003 to start, so make sure to quit any FileMaker Pro client before proceeding.

Open Terminal.app, drag the `install.sh` from the `build` folder into the terminal window, hit return and give your server instance a name. Or just let it be tagged with an ID.

After the installation process is finished, check the Dashboard in Docker Desktop, there should be a running container named **fms-[name-tag]**.

Open the admin console by clicking the *Open in Browser* button in the container actions or try with https://localhost:16000. 


Mind that:
- **Chrome** does not work without a valid certificate
- **Safari** lets you bypass the certificate warning
- **Edge** lets you bypass the certificate warning, but opened from Docker Dashboard, the URL comes as an `http` link, and you need to append `https://`.

Clicking the CLI button will open a terminal window where you can use the fmsadmin command to control your server.





## Installation on Windows 10

**Important**: As of now, there is a caveat when running both FileMaker Server (in Docker) and FileMaker Pro at the same time on a Windows machine. FileMaker Pro also binds port 5003 (exclusively) on launch, and it is not possible to make a connection to the local server.  
There is a workaround though: If you open port 5003 before, with a tool like [TCP Listen](https://www.allscoop.com/tcp-listen.php), FileMaker Pro cannot take that port and instead accesses FileMaker Server in the Docker environment. 

#### WSL2

Install the Windows Subsystem for Linux **WSL** first. To do so, follow these instructions: https://docs.microsoft.com/de-de/windows/wsl/install-win10 ("Manual Installation Steps").

#### Ubuntu

Download and install Ubuntu from the Windows Store. The `Ubuntu` and `Ubuntu 20.04` apps are identical, just make sure it is the one offered by Canonical Group Limited.
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

#### Systemd

Now, to provide the necessary systemd service to the Ubuntu host, run this script:
https://github.com/damionGans/ubuntu-wsl2-systemd-script

Again, restart Ubuntu by exiting and starting again.



#### Docker Desktop

Download and install the latest version of Docker Desktop.

In the Docker Desktop settings: Under **General**, activate WSL2 based engine and under **Resources > WSL Integration** activate WSL2 support for your Ubuntu installation.
It may be necessary to restart both Docker Desktop and Ubuntu (or even reboot Windows) to get the integration into a working state. You can test and see if `docker ps` from the Ubuntu terminal throws any error.



#### Repo

Clone or download and unzip the repo.

Since it is recommended not to mount volumes from the Windows filesystem into a WSL2 Docker container but rather directly from the WSL filesystem, copy the installer into your Linux home directory:

```
sudo cp -rv /mnt/c/Users/your_windows_username/Downloads/fmg-dockerfms-main/fmg-dockerfms-main/* ~/fms
```



#### FileMaker Server

Download a copy of the FileMaker Server installer for Linux from your Claris account page, unpack the zip file and move the Red Hat Package Manager (rpm) file to the `build` folder:

```
~/fms/build/filemaker_server-19.2.1-23.x86_64.rpm
```

You can also put a link into the config.txt instead, the installer will be downloaded then.

You can adjust the settings in the *Assisted Install.txt* file, but you don't need to. The server admin console login will be admin/admin then, which can be changed later.



#### SSL Certificate

If you have a certificate that you might want to use for this server, simply copy the files (key, cert and intermediate) into the `build` directory, the installer will automatically look for the appropriate file endings (.pem, .crt and .ca-bundle). If you don' t provide any, you can install them later or select the default self-signed certificate on first admin console launch. 



#### Run install script

It may be necessary to grant an access rule for Docker Desktop in the **Windows firewall** when prompted. 

Run the installer :
```
./fms/build/install.sh
```

When the installation process is finished, your server will be startet automatically.

Open the admin console by clicking the *Open in Browser* button in the container actions – if that fails, try with https://localhost:16000. 


Mind that:

- **Chrome** does not work without a valid certificate
- **Edge** lets you bypass the certificate warning, but opened from Docker Dashboard, the URL comes as an `http` link, and you need to append `https://`.

Clicking the CLI button will open a terminal window where you can use the fmsadmin command to control your server.



#### Issues: 

Folders (for databases, backups…) are created on container start but not reconnected if you reboot and start Docker Desktop again. Existing files will not be overwritten, but new volumes must be created and attached to the local folders.
This happens in the `start_server` script, where the wsl directory is checked before starting the container. It is considered a workaround to this issue: [docker/for-win/issues/10060](https://github.com/docker/for-win/issues/10060)

If Docker Desktop for Windows fails to restart, rebooting Windows may be the fastest way solve this. 



## Tools

To handle some issues and restrictions, there are scripts for controlling your server instances in the `tools/` subdirectory:



**setup_instance.sh**

Lets you set an instance name or ID and creates bind volumes. Also looks for fms-data directories.

**remove_instance.sh**

Removes volumes and container, but not the fms-data directory. Delete instance directory manually.

**start_server.sh**

Start this server instance.

**stop_server.sh**

Stops server, you will be prompted to close any open databases.

**global_cleanup.sh**

This removes any dangling volumes (attached to no container) and also removes the docker network `fms-net`, when no container named `fms-*` is left.
It is necessary especially on Windows, where bind volumes get recreated after every reboot, and the old ones persist.

### 


## Administration


### Stopping and Restarting the Server

At the moment, quitting Docker Desktop will not gracefully close your databases or stop the server. To prevent your databases from being corrupted from a hard shutdown, always stop the container in Docker Dashboard, alternatively with `tools/stop_server.sh` or use the `fmsadmin stop server` command beforehand.



### Accessing files

Relevant directories are being mounted into the container as volumes. These volumes are bound to their corresponding folders on the host in the `fms-data` folder. In case the container is removed, it is possible to run a new container with the persisted state with the `tools/start_server` script. It is recommended not to edit these files while the server is running.

The directories include databases, logs, configs and extensions.

On Windows, the Linux filesystem can also be mounted as network volume into the Windows Explorer by using a path like:

```
\\wsl$\your_linux_distro\
```

Due to permissions, this should only be used read-only.



### Managing Instances 

(macOS only) 

If you need more than one instance, you can simply duplicate an installation (will also duplicate settings, logs and databases, setup new instance name with `tools/setup_instance`)

It is possible to have multiple instances of these installations, but you can run only one at a time. Each installation is bound to its directory, where the `fms-data` (FileMaker Server directories) directory and the `.env` (name-tag) file are located. 



### Snapshots

(tested on macOS only)

As all settings and database files are stored in the fms-data folder, you can create copies to capture states of the server.



