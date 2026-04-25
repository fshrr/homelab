#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Debian 13 (Trixie) VM Golden Image Setup
# Run as non-root user with sudo privileges
# ============================================================

# Prompt for SSH port
while true; do
  read -rp "Enter SSH port: " SSH_PORT
  if [[ "$SSH_PORT" =~ ^[0-9]+$ ]] && (( SSH_PORT >= 1 && SSH_PORT <= 65535 )); then
    break
  fi
  echo "Error: Invalid port number. Must be 1-65535."
done

echo "==> Using SSH port: $SSH_PORT"

# Prompt for dotfiles profile
read -rp "Enter dotfiles profile [default: server]: " DOTFILES_PROFILE
DOTFILES_PROFILE="${DOTFILES_PROFILE:-server}"

# ------------------------------------------------------------
echo "==> Configuring apt sources (non-free enabled)..."
sudo tee /etc/apt/sources.list.d/debian.sources > /dev/null <<EOF
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

echo "==> Updating package index..."
sudo apt update

echo "==> Installing packages..."
sudo apt install -y \
  curl ca-certificates gnupg lsb-release \
  build-essential btop zip unzip apt-transport-https \
  net-tools ncdu apache2-utils speedtest-cli \
  neovim zsh tmux nfs-common fzf zoxide eza \
  iozone3 git git-delta ethtool tre-command stow \
  ffmpeg 7zip jq poppler-utils fd-find ripgrep imagemagick \
  ufw fail2ban unattended-upgrades \
  chrony lazygit cloud-init cloud-guest-utils qemu-guest-agent

echo "==> Installing yazi..."
YAZI_VERSION=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
curl -Lo /tmp/yazi.zip "https://github.com/sxyazi/yazi/releases/download/${YAZI_VERSION}/yazi-x86_64-unknown-linux-gnu.zip"
unzip -q /tmp/yazi.zip -d /tmp/yazi
sudo install -m 0755 /tmp/yazi/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/yazi
sudo install -m 0755 /tmp/yazi/yazi-x86_64-unknown-linux-gnu/ya /usr/local/bin/ya
rm -rf /tmp/yazi /tmp/yazi.zip

# ------------------------------------------------------------
echo "==> Tuning VM sysctl parameters..."
sudo tee -a /etc/sysctl.conf > /dev/null <<EOF

# Prefer RAM over swap — only swap as last resort (default is 60)
vm.swappiness=10

# Hold filesystem metadata cache longer — faster repeated file access (default is 100)
vm.vfs_cache_pressure=50

# Needed for VS Code, Docker, file watchers — default (~8192) is too low
fs.inotify.max_user_watches=262144
EOF
sudo sysctl -p

# ------------------------------------------------------------
echo "==> Applying kernel hardening..."
sudo tee /etc/sysctl.d/99-hardening.conf > /dev/null <<EOF
# Prevent rogue routers from silently changing this VM's routing table
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0

# Block symlink/hardlink privilege escalation tricks in /tmp and world-writable dirs
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_regular = 2
EOF
sudo sysctl --system

# ------------------------------------------------------------
echo "==> Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "==> Installing Oh My Posh..."
curl -s https://ohmyposh.dev/install.sh | bash -s

echo "==> Installing zinit..."
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"

echo "==> Installing uv (Python package manager)..."
curl -LsSf https://astral.sh/uv/install.sh | sh

echo "==> Installing thefuck..."
"$HOME/.local/bin/uv" tool install thefuck

echo "==> Cloning dotfiles..."
git clone https://github.com/fshrr/dotfiles ~/.dotfiles
cd ~/.dotfiles
./install.sh "$DOTFILES_PROFILE"
cd ~

echo "==> Setting zsh as default shell..."
chsh -s "$(which zsh)"

# ------------------------------------------------------------
echo "==> Enabling services..."
sudo systemctl start qemu-guest-agent
sudo systemctl enable fail2ban
sudo dpkg-reconfigure --priority=low unattended-upgrades

# ------------------------------------------------------------
echo "==> Configuring firewall (UFW)..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.2.0/24
sudo ufw allow "${SSH_PORT}"/tcp
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

# ------------------------------------------------------------
echo "==> Hardening SSH..."
sudo tee /etc/ssh/sshd_config.d/99-hardening.conf > /dev/null <<EOF
Port ${SSH_PORT}
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
MaxAuthTries 3
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
PermitEmptyPasswords no
EOF

sudo sshd -t && sudo systemctl restart sshd

# ------------------------------------------------------------
echo "==> Setting timezone and enabling time sync..."
sudo timedatectl set-timezone America/Toronto
sudo systemctl enable chrony && sudo systemctl start chrony

# ------------------------------------------------------------
echo "==> Installing Docker..."
sudo apt remove -y docker.io docker-compose docker-doc podman-docker containerd runc 2>/dev/null || true

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker "$USER"

echo "==> Installing lazydocker..."
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

# ------------------------------------------------------------
echo ""
echo "==> Setup complete!"
echo "    NOTE: Log out and back in for docker group membership to take effect."
