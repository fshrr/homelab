# Ansible

System configuration for VMs and LXCs. Complements `infra/tofu/` (which creates the VMs). Supersedes `scripts/vm_deb_start.sh` and `scripts/lxc_deb_start.sh`.

## Setup

```bash
uv tool install ansible-core ansible-lint   # or: brew install ansible
cd infra/ansible
ansible-galaxy collection install -r requirements.yml
```

## Roles

| Role | What it does |
|---|---|
| `common` | Baseline packages (the golden-image list), purge distro docker, sysctl tuning + hardening, timezone, chrony, unattended-upgrades, qemu-guest-agent, fail2ban |
| `ssh` | `sshd_config.d/99-hardening.conf`, validated before restart; `ssh.socket` override and fail2ban port pin when `ssh_port` is not 22 |
| `firewall` | UFW: allow in on `tailscale0`, 41641/udp, SSH from `lan_cidr`; deny everything else inbound |
| `tailscale` | deb822 repo, unattended join with an auth key passed via `file:`, `--ssh`, operator, fails on tag drift |
| `docker` | docker-ce + compose plugin, docker group, pinned lazydocker |
| `node` | NodeSource, `.npmrc` allow-scripts so node-pty builds under npm 11 |
| `dev_tools` | gh, Claude Code, pinned yazi / oh-my-posh / uv, zinit, dotfiles, zsh as login shell |
| `t3code` | pinned `npm -g t3`, system unit with `User=` ordered after tailscaled, `--tailscale-serve`, HTTPS probe |

Every role has `defaults/main.yml` with role-prefixed vars. Group vars in `inventory/group_vars/all.yml` feed them via `admin_user`, `timezone`, `lan_cidr`, `ssh_port`, `tailscale_*`, `dotfiles_profile`.

## Playbooks

### `playbooks/t3code.yml` — T3 Code server

Fresh Ubuntu 26.04 cloud-init clone → hardened dev VM running [T3 Code](https://www.npmjs.com/package/t3) headless over Tailscale.

Prereqs:
- VM cloned from the Proxmox cloud template with `cpu: host`, root disk resized, SSH key access for `admin_user`, passwordless sudo.
- Tailscale OAuth client with `auth_keys` scope for `tag:servers`, stored in Infisical at `/tailscale` as `TS_AUTHKEY` with value `tskey-client-...?ephemeral=false&preauthorized=true`. OAuth client secrets do not expire; plain auth keys do.
- Tailnet ACL has an `ssh` section covering `tag:servers` (for `tailscale_ssh: true`).
- Host listed under `t3code` in `inventory/hosts.yml`, `ansible_host` set to its MagicDNS name once joined (LAN IP for the very first run).

Run:

```bash
infisical run --path=/tailscale -- ansible-playbook playbooks/t3code.yml
```

Idempotent; second run reports `changed=0`.

## Updating pinned tools

Versions and sha256 live in each role's `defaults/main.yml` (`dev_tools_*_version`, `docker_lazydocker_*`, `t3code_version`). Bump both lines, commit, re-run. Hashes come from each project's release checksum asset:

```bash
curl -sL https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/v<ver>/checksums.txt | grep posh-linux-amd64
curl -sL https://github.com/astral-sh/uv/releases/download/<ver>/uv-x86_64-unknown-linux-gnu.tar.gz.sha256
curl -sL https://github.com/jesseduffield/lazydocker/releases/download/v<ver>/checksums.txt | grep Linux_x86_64
curl -sLo yazi.deb https://github.com/sxyazi/yazi/releases/download/v<ver>/yazi-x86_64-unknown-linux-gnu.deb && shasum -a 256 yazi.deb
```

Claude Code is unpinned on purpose (self-updating).

## Manual steps

`claude auth login`, `gh auth login`, `t3 pair --tailscale`.

Service management on the VM:

```bash
systemctl status t3code
journalctl -u t3code -f
```
