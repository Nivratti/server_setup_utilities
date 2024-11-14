#!/bin/bash

# Function to create a new sudo user
create_sudo_user() {
    read -p "Enter username for the new user: " username
    read -s -p "Enter password for the new user: " password
    echo

    # Create the user with the provided username and password
    sudo adduser --quiet --disabled-password --gecos "" $username
    echo "$username:$password" | sudo chpasswd

    # Add the user to the sudo group
    sudo usermod -aG sudo $username

    echo "User $username created and added to sudo group."
}

# Function to set up remote desktop
setup_remote_desktop() {
    # Update and upgrade the system
    sudo apt update
    sudo apt upgrade -y

    # Install the desktop environment and XRDP
    sudo apt install -y ubuntu-desktop xrdp

    # Enable the XRDP service
    sudo systemctl enable xrdp
    sudo systemctl start xrdp

    # Allow XRDP through the firewall
    sudo ufw allow 3389/tcp

    # Restart XRDP service
    sudo systemctl restart xrdp

    echo "Remote desktop setup completed. You can now connect via RDP."
}

# Main script execution
read -p "Do you want to create a new sudo user? (y/n): " create_user_choice
if [[ "$create_user_choice" =~ ^[Yy]$ ]]; then
    create_sudo_user
else
    echo "Skipping user creation."
fi

setup_remote_desktop
