# Server setup utilities
Utitlities- script and doc -- to setup xrdp, cuda libraries or other development tools on server

# Table of Contents

- [Usage](#usage)
  - [1. Add sudo user on Ubuntu](#1-add-sudo-user-on-ubuntu)
  - [2. Installing Miniconda and Python](#2-installing-miniconda-and-python)
  - [3. Installing Anaconda](#3-installing-anaconda)
  - [4. Docker compose](#4-docker-compose)
  - [5. Fixing cuda toolkit `nvcc --version` not visible issue](#5-fixing-cuda-toolkit-nvcc---version-not-visible-issue)
  - [6. Opening port on server](#6-opening-port-on-server)
  - [7. Setting up xrdp](#7-setting-up-xrdp)
  - [8. Setup Tweak tool](#8-setup-tweak-tool)
  - [9. Installing Google Chrome](#9-installing-google-chrome)
    
## Usage

### 1. Add sudo user on Ubuntu:

The adduser command creates a new user, plus a group and home directory for that user.

```console
sudo adduser newuser
```
You can replace newuser with any username you wish. The system will add the new user; then prompt you to enter a password. Enter a great secure password, then retype it to confirm.

To add user to sudo group, you can run command:
```console
sudo usermod -aG sudo newuser
```
Replace newuser with the username that you entered previously.

### 2. Installing Miniconda and Python

To install miniconda and Python, run below command. You can change base python version if required.

```console
# Download the Miniconda installer script from the Anaconda repository
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
sudo chmod +x Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda3
echo  'export PATH=$PATH:/opt/miniconda3/bin' >> ~/.bashrc 
source ~/.bashrc
conda init bash
source ~/.bashrc
conda
```

or if you want to install miniconda in user home directory, you can run below command

```console
CONDA_AUTO_UPDATE_CONDA=false && PATH=~/miniconda/bin:$PATH && curl -sLo ~/miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-py38_4.8.2-Linux-x86_64.sh && chmod +x ~/miniconda.sh && ~/miniconda.sh -b -p ~/miniconda && rm ~/miniconda.sh && conda install -y python==3.8.1
```

### 3. Installing Anaconda

To install conda, run commands.

```console
sudo apt-get update
wget https://repo.anaconda.com/archive/Anaconda3-2023.07-1-Linux-x86_64.sh
sudo chmod +x Anaconda3-2023.07-1-Linux-x86_64.sh
./Anaconda3-2023.07-1-Linux-x86_64.shh
source ~/.bashrc
conda info
```

### 4. Docker compose

1) Option to enable docker compose
Ubuntu 18:

```console
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu `lsb_release -cs` test"
sudo apt update -y
sudo apt install -y docker-ce
```

To use compose command now you can run
```console
docker compose
```

2) Old way -- dash inside command i.e. docker-compose
Docker compose mannual installation on ubuntu 18 e2enetwork cloud server.

```console
mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL https://github.com/docker/compose/releases/download/v2.7.0/docker-compose-linux-x86_64 -o  /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

### 5. Fixing cuda toolkit `nvcc --version` not visible issue:

i. Open bashrc fileby running command `$ sudo nano /etc/bash.bashrc`
ii. Append cuda library path
   ```console
   export PATH="/usr/local/cuda-11.8/bin:$PATH"
   export LD_LIBRARY_PATH="/usr/local/cuda-11.8/lib64:$LD_LIBRARY_PATH"
   ```
iii) Reload bashrc by running `source /etc/bash.bashrc` 
iv) Run `nvcc --version` command

### 6. Opening port on server:

On ubuntu system you can run command:

```console
sudo iptables -A INPUT -p tcp --dport xxxxx -j ACCEPT
```

Example to open 8010 port you can run:

```console
sudo iptables -A INPUT -p tcp --dport 8010 -j ACCEPT
```

### 7. Setting up xrdp:

1. Downlaod `setup_xrdp.bash` on server and allow execution permission.
   ```console
   wget https://raw.githubusercontent.com/Nivratti/server_setup_utilities/main/setup_xrdp.bash
   sudo chmod +x setup_xrdp.bash
   ```
   
2. Setup xrdp by running command.
   ```console
   ./setup_xrdp.bash
   ```
   
3. **IMP** Change password of user. 

### 8. Setup Tweak tool:

Install tweak tools: to fix folder icon not showing issue in Ubuntu 18 on e2enetwork server. [Azhar repo link](https://github.com/azroddin123/Setup_Learn/blob/master/Ubuntu%20Issues.)

```console
sudo add-apt-repository universe
sudo apt install gnome-tweak-tool
```

Run tweak tools and change **appearance** setting to **humanity**.

```console
gnome-tweaks
```

### 8. Installing google Chrome

To install chrome, run below commands from **user account instead of root**.

```console
sudo apt-get install -y fonts-liberation
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
```
