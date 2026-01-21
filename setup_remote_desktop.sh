#!/bin/bash
set -e

# Helper: run command with sudo if not root, directly if root
run_privileged() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

# Install sudo if missing (must be root for this)
ensure_sudo_installed() {
    if ! command -v sudo >/dev/null 2>&1; then
        if [[ $EUID -ne 0 ]]; then
            echo "ERROR: 'sudo' is not installed and you're not root."
            echo "Please run this script as root, or install sudo first:"
            echo "  su -c 'apt update && apt install -y sudo'"
            exit 1
        fi
        echo "Installing sudo (required for user management)..."
        apt update && apt install -y sudo
    fi
}

ensure_xsession_for_user() {
    local u="$1"
    local home
    home="$(getent passwd "$u" | cut -d: -f6)"
    run_privileged install -m 0644 /dev/stdin "$home/.xsession" <<<"startxfce4"
    run_privileged chown "$u:$u" "$home/.xsession"
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

    # Ensure sudo group exists (it should after sudo is installed)
    if ! getent group sudo >/dev/null 2>&1; then
        run_privileged groupadd sudo
    fi

    run_privileged adduser --quiet --disabled-password --gecos "" "$username"
    echo "$username:$password" | run_privileged chpasswd

    # Export the created username so the other function can see it
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
        run_privileged usermod -aG sudo "$username"
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
    run_privileged apt update

    # Desktop selection
    if [[ "$os" == "debian" ]]; then
        echo "Debian detected. Installing XFCE4 desktop."
        de_choice="X"
    else
        while true; do
            read -r -p "Which desktop environment do you want to install? [G]NOME / [X]FCE4 (default: X): " de_choice
            de_choice=${de_choice:-X}
            if [[ "$de_choice" =~ ^[GgXx]$ ]]; then break; fi
            echo "Invalid input. Please enter G for GNOME or X for XFCE4."
        done
    fi

    # Install desktop + XRDP + Xorg backend
    if [[ "$de_choice" =~ ^[Xx]$ ]]; then
        echo "Installing XFCE4 desktop..."
        run_privileged apt install -y xfce4 xfce4-goodies xorg dbus-x11 x11-xserver-utils xrdp xorgxrdp
    else
        echo "Installing GNOME desktop..."
        # ubuntu-desktop-minimal keeps it lighter; include xorgxrdp explicitly
        run_privileged apt install -y ubuntu-desktop-minimal xrdp xorgxrdp
        # Disable Wayland so XRDP uses Xorg (GNOME on Ubuntu)
        if [[ -f /etc/gdm3/custom.conf ]]; then
            if ! grep -q "^WaylandEnable=false" /etc/gdm3/custom.conf; then
                run_privileged sed -i 's/^#\?WaylandEnable=.*/WaylandEnable=false/' /etc/gdm3/custom.conf
            fi
            run_privileged systemctl restart gdm3 || true
        fi
    fi

    # Let xrdp read its TLS cert
    run_privileged adduser xrdp ssl-cert >/dev/null 2>&1 || true

    # For XFCE, ensure a session starts (both for root and the new user later)
    if [[ "$de_choice" =~ ^[Xx]$ ]]; then
        echo "startxfce4" | run_privileged tee /etc/skel/.xsession >/dev/null

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
    run_privileged systemctl enable xrdp --now
    run_privileged systemctl restart xrdp

    # Open local firewall if present
    if command -v ufw >/dev/null 2>&1; then
        run_privileged ufw allow 3389/tcp
        echo "Port 3389 opened in UFW."
    else
        echo "UFW not installed. Skipping UFW config."
    fi

    echo "NOTE: If you're on a cloud VM, also open TCP/3389 in your cloud security group / firewall."

    echo "✅ Remote desktop setup completed. Connect via RDP to port 3389."
}

set_india_timezone_locale() {
    # During setup, use a guaranteed locale to avoid bash warnings
    export LC_ALL=C.UTF-8 LANG=C.UTF-8

    echo "Installing timezone and locale packages..."
    run_privileged apt-get update -y
    run_privileged apt-get install -y tzdata locales

    # Timezone
    if command -v timedatectl >/dev/null 2>&1; then
        run_privileged timedatectl set-timezone Asia/Kolkata
    else
        run_privileged ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
        echo "Asia/Kolkata" | run_privileged tee /etc/timezone >/dev/null
        run_privileged dpkg-reconfigure -f noninteractive tzdata
    fi

    # Ensure correct line in /etc/locale.gen (no malformed entries)
    run_privileged sed -ri '/^\s*en_IN(\.UTF-8)?\s*$/d' /etc/locale.gen

    # Uncomment en_IN.UTF-8 if it exists as a comment, or add it
    if grep -Eq '^#\s*en_IN\.UTF-8\s+UTF-8' /etc/locale.gen; then
        run_privileged sed -ri 's/^#\s*(en_IN\.UTF-8\s+UTF-8)/\1/' /etc/locale.gen
    elif ! grep -Eq '^\s*en_IN\.UTF-8\s+UTF-8' /etc/locale.gen; then
        echo 'en_IN.UTF-8 UTF-8' | run_privileged tee -a /etc/locale.gen >/dev/null
    fi

    # Keep a safe fallback around
    if grep -Eq '^#\s*C\.UTF-8\s+UTF-8' /etc/locale.gen; then
        run_privileged sed -ri 's/^#\s*(C\.UTF-8\s+UTF-8)/\1/' /etc/locale.gen
    elif ! grep -Eq '^\s*C\.UTF-8\s+UTF-8' /etc/locale.gen; then
        echo 'C.UTF-8 UTF-8' | run_privileged tee -a /etc/locale.gen >/dev/null
    fi

    # Generate locales
    echo "Generating locales..."
    run_privileged locale-gen

    # Set system default locale
    if command -v localectl >/dev/null 2>&1; then
        run_privileged localectl set-locale LANG=en_IN.UTF-8 LANGUAGE="en_IN:en"
    else
        run_privileged update-locale LANG=en_IN.UTF-8 LANGUAGE="en_IN:en"
    fi

    # Make sure /etc/default/locale has no LC_ALL line (it causes issues)
    if [[ -f /etc/default/locale ]]; then
        if grep -q '^LC_ALL=' /etc/default/locale; then
            run_privileged sed -ri '/^LC_ALL=/d' /etc/default/locale
        fi
    fi

    # For the current shell/session
    unset LC_ALL
    export LANG=en_IN.UTF-8
    export LANGUAGE=en_IN:en

    # Verify
    echo ""
    echo "Locale configuration complete. Current settings:"
    locale 2>/dev/null || echo "(locale command unavailable)"
    echo ""
    echo "Timezone: $(cat /etc/timezone 2>/dev/null || timedatectl show -p Timezone --value 2>/dev/null || echo 'unknown')"
}

# ============== MAIN ==============
echo "========================================"
echo "  Remote Desktop Setup Script"
echo "  Supports: Ubuntu 24+ / Debian 12+"
echo "========================================"
echo ""

# Step 0: Ensure sudo is available
ensure_sudo_installed

# Step 1: Create user (optional)
setup_new_user_account

# Step 2: Install desktop + XRDP
setup_remote_desktop

# Step 3: Set timezone and locale
set_india_timezone_locale

echo ""
echo "========================================"
echo "  Setup Complete!"
echo "========================================"
echo ""
echo "You can now connect via RDP on port 3389."
if [[ -n "$NEW_USERNAME" ]]; then
    echo "Login with user: $NEW_USERNAME"
fi
echo ""
