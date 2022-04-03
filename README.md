# Server setup utilities
Utitlities- script and doc -- to setup xrdp, cuda libraries or other development tools on server

## Recent updates:

1. A
## Usage

### 1. Setting up xrdp:

1. Downlaod `setup_xrdp.bash` on server and allow execution permission.
   ```
   $ sudo chmod +x setup_xrdp.bash
   ```
   
2. Setup xrdp by running command.
   ```
   $ ./setup_xrdp.bash
   ```
   
3. **IMP** Change password of user. 


## 2. Setup Tweak tool:

Install tweak tools: to fix folder icon not showing issue in Ubuntu 18 on e2enetwork server. [Azhar repo link](https://github.com/azroddin123/Setup_Learn/blob/master/Ubuntu%20Issues.)

```console
$ sudo add-apt-repository universe
$ sudo apt install gnome-tweak-tool
```

Run tweak tools and change **appearance** setting to **humanity**.

```console
$ gnome-tweaks
```

## 3. Fixing cuda toolkit `nvcc --version` not visible issue:

i. Open bashrc fileby running command `$ /etc/bash.bashrc`
ii. Append cuda library path
   ```
   export PATH="/usr/local/cuda-11.3/bin:$PATH"
   export LD_LIBRARY_PATH="/usr/local/cuda-11.3/lib64:$LD_LIBRARY_PATH"
   ```
