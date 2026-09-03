# Ansible

System configuration for VMs and LXCs. Complements `infra/tofu/` (which creates the VMs).

## Setup

```bash
uv tool install ansible-core   # or: brew install ansible
cd infra/ansible
ansible-galaxy collection install -r requirements.yml
```

## Playbooks

### `playbooks/t3code.yml` — T3 Code server

Turns a fresh Ubuntu cloud-init VM into a headless [T3 Code](https://www.npmjs.com/package/t3) server reachable over Tailscale.

Installs: build tools, Tailscale (joins tailnet, tagged), Node.js (NodeSource), Docker, GitHub CLI, Claude Code, `t3` as a user-level systemd service with `--tailscale-serve`.

Prereqs:
- VM cloned from the Proxmox cloud template with SSH key access for `fahim` and passwordless sudo.
- Tailscale OAuth client with `auth_keys` scope for `tag:servers`, stored in Infisical at `/tailscale` as `TS_AUTHKEY` with value `tskey-client-...?ephemeral=false&preauthorized=true`. OAuth client secrets do not expire; plain auth keys do.
- Host listed under `t3code` in `inventory/hosts.yml`.

Run:

```bash
infisical run --path=/tailscale -- ansible-playbook playbooks/t3code.yml
```

Idempotent. Re-run after bumping `t3_version` (pinned) in `inventory/group_vars/t3code.yml` to update.

Manual steps left over (interactive auth): `claude auth login`, `gh auth login`, and `t3 pair --tailscale` to get a pairing QR.

Service management on the VM:

```bash
systemctl --user status t3code
journalctl --user -u t3code -f
```
