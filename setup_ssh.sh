#!/bin/bash

echo ""
echo "🔐 SSH Key Setup Automation"
echo "---------------------------"

DEFAULT_KEY_FILE="id_rsa.pub"
TEMP_KEY_FILE="temp_pubkey.pub"

# 1. Detect Linux Distribution
get_os_type() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# 2. Detect Package Manager
get_package_manager() {
    if command -v apt &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# 3. Detect SSH service name (some use ssh, others sshd)
get_ssh_service_name() {
    if systemctl list-units --type=service | grep -q "sshd.service"; then
        echo "sshd"
    else
        echo "ssh"
    fi
}

OS_TYPE=$(get_os_type)
PKG_MGR=$(get_package_manager)
SSH_SERVICE=$(get_ssh_service_name)

echo "🧠 OS Detected: $OS_TYPE"
echo "📦 Package Manager: $PKG_MGR"
echo "🔁 SSH Service: $SSH_SERVICE"

# 4. Ensure Git is installed
if ! command -v git &>/dev/null; then
    echo "⚙️ Installing git..."
    case "$PKG_MGR" in
        apt) sudo apt update && sudo apt install git -y ;;
        dnf) sudo dnf install git -y ;;
        yum) sudo yum install git -y ;;
        pacman) sudo pacman -Sy git ;;
        *) echo "❌ Unsupported package manager. Please install git manually."; exit 1 ;;
    esac
fi

# 5. Get Public Key
if [ -n "$1" ] && [ -f "$1" ]; then
    PUBLIC_KEY_FILE="$1"
    echo "✅ Using provided key file: $1"
elif [ -f "$DEFAULT_KEY_FILE" ]; then
    PUBLIC_KEY_FILE="$DEFAULT_KEY_FILE"
    echo "✅ Found default key: $DEFAULT_KEY_FILE"
else
    echo "📝 No public key found. Paste it below:"
    read -p "Paste your SSH public key: " pasted_key
    if [[ "$pasted_key" == ssh-* ]]; then
        echo "$pasted_key" > "$TEMP_KEY_FILE"
        PUBLIC_KEY_FILE="$TEMP_KEY_FILE"
        echo "✅ Saved pasted key to temp file."
    else
        echo "❌ Invalid key format. Exiting."
        exit 1
    fi
fi

# 6. Set up .ssh and authorized_keys
TARGET_USER="$USER"
USER_HOME=$(eval echo "~$TARGET_USER")
mkdir -p "$USER_HOME/.ssh"
chmod 700 "$USER_HOME/.ssh"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.ssh"

cat "$PUBLIC_KEY_FILE" >> "$USER_HOME/.ssh/authorized_keys"
chmod 600 "$USER_HOME/.ssh/authorized_keys"
chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.ssh/authorized_keys"

echo "✅ Public key added to ~/.ssh/authorized_keys"

# 7. Backup and edit sshd_config
echo "📦 Backing up /etc/ssh/sshd_config"
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

echo "🔐 Securing sshd_config"
sudo sed -i 's/^#\?PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PubkeyAuthentication no/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i 's/^#\?UsePAM no/UsePAM yes/g' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin yes/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
if ! grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
    echo "PermitRootLogin prohibit-password" | sudo tee -a /etc/ssh/sshd_config > /dev/null
fi

# 8. Restart SSH service
echo "🔁 Restarting SSH service: $SSH_SERVICE"
sudo systemctl restart "$SSH_SERVICE"

# 9. Show public IP
echo "-----------------------------------"
echo "Your Lab Machine's Public IP is:"
echo ""
curl -s ifconfig.me
echo ""
echo "-----------------------------------"
echo ""

#10. update system
echo "-> Starting system package update in background (this may take a moment)..."
sudo "$PKG_MGR" update -y > /dev/null 2>&1 &
echo "   Background update initiated. You can check it with 'ps aux | grep $PKG_MGR'."


# 11. Clean temp file
rm -f "$TEMP_KEY_FILE"

echo ""
echo " All done! You can now SSH using your private key:"
echo "    ssh -i /path/to/private_key $TARGET_USER@<server_ip>"
