ensure_xsession_for_user() {
  local u="$1"
  local home
  home="$(getent passwd "$u" | cut -d: -f6)"
  sudo install -m 0644 /dev/stdin "$home/.xsession" <<<"startxfce4"
  sudo chown "$u:$u" "$home/.xsession"
}

setup_new_user_account() {
    # Ask whether to create a user (strict Y/N with default Y)
    while true; do
        read -r -p "Do you want to create a new user? [Y/n]: " create_user
        create_user=${create_user:-Y}
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

    read -r -p "Enter username for the new user: " username

    while true; do
        read -s -r -p "Enter password for the new user: " password; echo
        read -s -r -p "Confirm password: " confirm_password; echo
        if [[ -z "$password" ]]; then
            echo "Password cannot be empty."
        elif [[ "$password" != "$confirm_password" ]]; then
            echo "Passwords do not match. Please try again."
        else
            break
        fi
    done

    # Ensure sudo exists on Debian minimal
    if ! getent group sudo >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y sudo
    fi

    sudo adduser --quiet --disabled-password --gecos "" "$username"
    echo "$username:$password" | sudo chpasswd

    # export the created username so the other function can see it
    export NEW_USERNAME="$username"

    while true; do
        read -r -p "Should the user be added to the sudo group? [Y/n]: " add_sudo
        add_sudo=${add_sudo:-Y}
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

    echo "Updating system..."
    sudo apt update && sudo apt -y upgrade

    # Desktop selection
    if [[ "$os" == "debian" ]]; then
        echo "Debian detected. Installing XFCE4 desktop."
        de_choice="X"
    else
        while true; do
            read -r -p "Which desktop environment do you want to install? [G]NOME / [X]FCE4 (default: G): " de_choice
            de_choice=${de_choice:-G}
            if [[ "$de_choice" =~ ^[GgXx]$ ]]; then break; fi
            echo "Invalid input. Please enter G for GNOME or X for XFCE4."
        done
    fi

    # Install desktop + XRDP + Xorg backend
    if [[ "$de_choice" =~ ^[Xx]$ ]]; then
        echo "Installing XFCE4 desktop..."
        sudo apt install -y xfce4 xfce4-goodies xorg dbus-x11 x11-xserver-utils xrdp xorgxrdp
    else
        echo "Installing GNOME desktop..."
        # ubuntu-desktop-minimal keeps it lighter; include xorgxrdp explicitly
        sudo apt install -y ubuntu-desktop-minimal xrdp xorgxrdp
        # Disable Wayland so XRDP uses Xorg (GNOME on Ubuntu)
        if [[ -f /etc/gdm3/custom.conf ]]; then
            if ! grep -q "^WaylandEnable=false" /etc/gdm3/custom.conf; then
                sudo sed -i 's/^#\?WaylandEnable=.*/WaylandEnable=false/' /etc/gdm3/custom.conf
            fi
            sudo systemctl restart gdm3 || true
        fi
    fi

    # Let xrdp read its TLS cert
    sudo adduser xrdp ssl-cert >/dev/null 2>&1 || true

    # For XFCE, ensure a session starts (both for root and the new user later)
    if [[ "$de_choice" =~ ^[Xx]$ ]]; then
        echo "startxfce4" | sudo tee /etc/skel/.xsession >/dev/null

        # Also ensure current user can test immediately
        if [[ ! -f "$HOME/.xsession" ]]; then
            echo "startxfce4" > "$HOME/.xsession"
        fi

        # If a new user was created earlier in this run, fix theirs too
        if [[ -n "$NEW_USERNAME" ]]; then
            ensure_xsession_for_user "$NEW_USERNAME"
        fi
    fi

    echo "Configuring XRDP service..."
    sudo systemctl enable xrdp --now
    sudo systemctl restart xrdp

    # Open local firewall if present
    if command -v ufw >/dev/null 2>&1; then
        sudo ufw allow 3389/tcp
        echo "Port 3389 opened in UFW."
    else
        echo "UFW not installed. Skipping UFW config."
    fi

    echo "NOTE: If you're on a cloud VM, also open TCP/3389 in your cloud security group / firewall."

    echo "✅ Remote desktop setup completed. Connect via RDP to port 3389."
}

set_india_timezone_locale() {
    # Set Kolkata timezone if not already set
    if [ "$(timedatectl show -p Timezone --value)" != "Asia/Kolkata" ]; then
        sudo apt-get update -y && sudo apt-get install -y tzdata
        sudo timedatectl set-timezone Asia/Kolkata
    fi

    # Set Indian locale if not already present
    if ! locale -a | grep -q '^en_IN\.UTF-8$'; then
        sudo apt-get install -y locales
        sudo sed -i 's/^# *en_IN.UTF-8/en_IN.UTF-8/' /etc/locale.gen
        sudo locale-gen
        sudo update-locale LANG=en_IN.UTF-8
    fi
}

setup_new_user_account
setup_remote_desktop
set_india_timezone_locale
