# fmg-dockerfms
Run FileMaker Server for Linux in Docker Desktop for Mac or Windows. Everything you need to automatically build a ready-to-run Docker image.

**Windows**: the install.sh is currently having issues with systemd. 


## Installation on macOS



### Docker Desktop

Download and install the latest version of Docker Desktop.



### Repo

Clone or download the repo an move it to your documents folder. You may rename it to something like

```~/Documents/FMS-Linux
~/Documents/FMS-Linux
```



### FileMaker Server

Download a copy of the FileMaker Server installer for Linux from your Claris account page, unpack the zip file and move the Red Hat Package Manager (rpm) file to the build folder in the repo. You can also put a  link into the config.txt, the installer will be downloaded instead then. 

With the current version of the installer it will look like this:

```
~/Documents/FMS-Linux/build/filemaker_server-19.2.1-23.x86_64.rpm
```

You can adjust the settings in the *Assisted Install.txt* file but you don't need to. The server admin console login will be admin/admin then, which can be changed later.



### SSL Certificate

If you have a certificate that you might want to use for this server, simply copy the files (key, cert and intermiediate) into the *build* directory, the installer will automatically look for the appropriate file endings (.pem, .crt and .ca-bundle). If you don' t provide any, the server will use the default self-signed certificate instead.



### Build Image and run Container

Open Terminal.app, drag the **install.sh** into the terminal window and hit return.

After the install process is finished, check the Dashboard in Docker Desktop, there should be a running container named **fms** (fmc-c if installed with a certificate).

Open the admin console by clicking the *Open in Browser* button in the container actions. If you installed without certificate you will have to confirm the self-signed one.

Clicking the CLI button will open a terminal window where you can use the fmsadmin command to control your server.







## Installation on Windows 10



In addition to the macOS instructions you will have to install the Windows Subsystem for Linux WSL first. To do so, follow these instructions: https://docs.microsoft.com/de-de/windows/wsl/install-win10

Download and install a Linux distribution of your preference and run it. 





## Administration



### Stopping and Restarting the Server

At the moment, stopping the container or quitting Docker Desktop will not gracefully close your databases or stop the server. To prevent your databases from being currupted by the hard shutdown, always use the *fmsadmin stop server* command beforehand.

## 

