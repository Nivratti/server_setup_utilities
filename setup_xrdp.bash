#!/bin/bash
sudo apt update
sudo apt install -y xfce4 xfce4-goodies xorg dbus-x11 x11-xserver-utils

# install xrdp
sudo apt install -y xrdp
sudo systemctl status xrdp
sudo adduser xrdp ssl-cert

# 3. Configuring Xrdp
sudo echo 'exec startxfce4' >> /etc/xrdp/xrdp.ini

# 4. Restart xrdp
sudo systemctl restart xrdp

# 5. Configuring firewall
sudo apt install ufw
sudo ufw allow from 192.168.1.0/24 to any
sudo ufw allow 3389

sudo iptables -A INPUT -p tcp --dport 3389 -j ACCEPT

# configure-anybody-to-run-x-in-a-one-liner
sudo sed -i \
    's/allowed_users=console/allowed_users=anybody/' /etc/X11/Xwrapper.config

# 7. restart xrdp
sudo systemctl restart xrdp

# 8. create user and grant root permissions
# sudo adduser [username]
# sudo usermod -aG sudo [username]
## dont give any space in variable value assignment
username="nivratti"
useradd -c "B. Nivratti" -m  "${username}"
# create with dummy password -- change after script execution end
echo "${username}:mypassword" | chpasswd
echo "Urgent.. Please change password for user ${username} by running cmd: $ passwd ${username}"

sudo usermod -aG sudo $username
