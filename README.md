# 🚀 SSH Key Setup Automation Script

This script automates the setup of SSH key-based authentication across multiple Linux distributions. It's perfect for:

- Quickly setting up new **lab machines**
- Hardening servers by **disabling password logins**
- Allowing remote login without needing to manually edit SSH configs

---

## 📦 Features

- Works on **Debian, Ubuntu, Fedora, Arch, Rocky, AlmaLinux**, and more
- Accepts your public key via:
  - A `.pub` file (e.g., `id_rsa.pub`)
  - Manual input (paste directly)
- Backs up your existing SSH configuration
- Automatically modifies `sshd_config` for best security
- Restarts the correct SSH service (depending on OS)
- Runs system updates in the background

---

##  Usage

###  Option 1: Fork and Replace Key

1. **Fork this repo**
2. Replace `id_rsa.pub` with your public key
3. On your target Linux machine:

```
git clone https://github.com/YourUsername/ssh.git
cd ssh
bash setup_ssh.sh
```

### Option 2: Clone & Provide Key Path or Paste It
Clone the repo:
```
git clone https://github.com/YourUsername/ssh.git
cd ssh
```
Run the script and follow the prompt:
```
bash setup_ssh.sh /path/to/key
```
You can:

Provide a path to your .pub key (e.g., /home/user/.ssh/id_rsa.pub)

Or paste your key directly when prompted

<br><br>
## 🧠 Why Two Modes?

This script works in **two flexible ways**:

### **🅰️ Fork & Push Your Key**

> Best when you **cannot transfer files** to your server.

🅱️ Direct Clone & Pass Key
Best when you can move your key to the server.


<br><br>
### What this script Does
Adds your key to ~/.ssh/authorized_keys

Updates /etc/ssh/sshd_config to:

Disable PasswordAuthentication

Enable PubkeyAuthentication

Set PermitRootLogin prohibit-password

Backs up existing sshd_config

Restarts the appropriate SSH service based on detected OS

Starts a silent apt, dnf, or pacman update in the background

Shows your public IP address at the end for easy connection
<br><br>
### 🛑 Warnings
Never share your private key

Make sure key-based login works before locking down password access

You need sudo access to modify SSH and restart services

Example SSH Login
```
ssh -i ~/.ssh/your_private_key username@your_public_ip
```

### 💡 Contribute or Fork
Feel free to fork, modify, or suggest improvements!
