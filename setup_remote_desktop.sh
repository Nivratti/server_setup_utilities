
setup_new_user_account() {
    # Ask whether to create a user (strict Y/N only)
    while true; do
        read -p "Do you want to create a new user? [Y/n]: " create_user
        if [[ "$create_user" =~ ^[YyNn]$ ]]; then
            break
        else
            echo "Invalid input. Please enter Y or N."
        fi
    done

    if [[ "$create_user" =~ ^[Nn]$ ]]; then
        echo "Skipping user creation."
        return
    fi

    # Get username
    read -p "Enter username for the new user: " username

    # Ask password twice and match
    while true; do
        read -s -p "Enter password for the new user: " password
        echo
        read -s -p "Confirm password: " confirm_password
        echo
        if [[ -z "$password" ]]; then
            echo "Password cannot be empty."
        elif [[ "$password" != "$confirm_password" ]]; then
            echo "Passwords do not match. Please try again."
        else
            break
        fi
    done

    # Create user and set password
    sudo adduser --quiet --disabled-password --gecos "" "$username"
    echo "$username:$password" | sudo chpasswd

    # Ask if user should be added to sudo group
    while true; do
        read -p "Should the user be added to the sudo group? [Y/n]: " add_sudo
        if [[ "$add_sudo" =~ ^[YyNn]$ ]]; then
            break
        else
            echo "Invalid input. Please enter Y or N."
        fi
    done

    if [[ "$add_sudo" =~ ^[Yy]$ ]]; then
        sudo usermod -aG sudo "$username"
        echo "User '$username' created and added to sudo group."
    else
        echo "User '$username' created without sudo privileges."
    fi
}

setup_remote_desktop() {
    # Detect OS type
    if grep -qi "ubuntu" /etc/os-release; then
        os="ubuntu"
    elif grep -qi "debian" /etc/os-release; then
        os="debian"
    else
        echo "Unsupported OS. Only Debian and Ubuntu are supported."
        return 1
    fi

    # Update and upgrade system
    echo "Updating system..."
    sudo apt update && sudo apt upgrade -y

    # Determine desktop environment
    if [[ "$os" == "debian" ]]; then
        echo "Debian detected. Installing XFCE4 desktop."
        de_choice="X"
    else
        while true; do
            read -p "Which desktop environment do you want to install? [G]NOME / [X]FCE4 (default: G): " de_choice
            de_choice=${de_choice:-G}
            if [[ "$de_choice" =~ ^[GgXx]$ ]]; then
                break
            else
                echo "Invalid input. Please enter G for GNOME or X for XFCE4."
            fi
        done
    fi

    # Install desktop environment
    if [[ "$de_choice" =~ ^[Xx]$ ]]; then
        echo "Installing XFCE4 desktop..."
        sudo apt install -y xfce4 xfce4-goodies xorg dbus-x11 x11-xserver-utils xrdp
    else
        echo "Installing GNOME desktop..."
        sudo apt install -y ubuntu-desktop xrdp
    fi

    # Enable and start XRDP
    echo "Configuring XRDP service..."
    sudo systemctl enable xrdp
    sudo systemctl start xrdp

    # Allow port 3389 through UFW if available
    if command -v ufw >/dev/null 2>&1; then
        sudo ufw allow 3389/tcp
        echo "Port 3389 opened in UFW."
    else
        echo "UFW not installed. Skipping firewall configuration."
    fi

    echo "✅ Remote desktop setup completed. You can now connect using RDP to port 3389."
}


setup_new_user_account
setup_remote_desktop
