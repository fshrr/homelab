#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Debian 13 (Trixie) LXC Golden Image Setup
# Run as root
# ============================================================

# Prompt for SSH port
read -rp "Enter SSH port [default: 22]: " SSH_PORT
SSH_PORT="${SSH_PORT:-22}"

if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]] || (( SSH_PORT < 1 || SSH_PORT > 65535 )); then
  echo "Error: Invalid port number. Must be 1-65535."
  exit 1
fi

echo "==> Using SSH port: $SSH_PORT"

# Prompt for dotfiles profile
read -rp "Enter dotfiles profile [default: server]: " DOTFILES_PROFILE
DOTFILES_PROFILE="${DOTFILES_PROFILE:-server}"

# ------------------------------------------------------------
echo "==> Configuring apt sources (non-free enabled)..."
tee /etc/apt/sources.list.d/debian.sources > /dev/null <<EOF
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
apt update

echo "==> Installing packages..."
apt install -y \
  curl ca-certificates gnupg lsb-release \
  build-essential btop zip unzip apt-transport-https \
  net-tools ncdu apache2-utils speedtest-cli \
  neovim zsh tmux nfs-common fzf zoxide eza \
  iozone3 git git-delta ethtool tre-command \
  ufw fail2ban unattended-upgrades stow \
  ffmpeg 7zip jq poppler-utils fd-find ripgrep imagemagick \
  snapd

echo "==> Installing snap core..."
snap install core

echo "==> Installing yazi..."
snap install yazi --classic --edge

echo "==> Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "==> Installing Oh My Posh..."
curl -s https://ohmyposh.dev/install.sh | bash -s

echo "==> Installing zinit..."
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"

echo "==> Installing uv (Python package manager)..."
curl -LsSf https://astral.sh/uv/install.sh | sh

echo "==> Cloning dotfiles..."
git clone https://github.com/fshrr/dotfiles ~/.dotfiles
cd ~/.dotfiles
./install.sh "$DOTFILES_PROFILE"
cd ~

echo "==> Setting zsh as default shell..."
chsh -s "$(which zsh)"

echo "==> Enabling services..."
systemctl enable fail2ban
dpkg-reconfigure --priority=low unattended-upgrades

# ------------------------------------------------------------
echo "==> Configuring firewall (UFW)..."
ufw default deny incoming
ufw default allow outgoing
ufw allow from 192.168.2.0/24
ufw allow "${SSH_PORT}"/tcp
ufw --force enable

# ------------------------------------------------------------
echo "==> Hardening SSH..."
tee /etc/ssh/sshd_config.d/99-hardening.conf > /dev/null <<EOF
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

sshd -t && systemctl restart sshd

# ------------------------------------------------------------
echo "==> Setting timezone..."
timedatectl set-timezone America/Toronto