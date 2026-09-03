---
name: proxmox-cloud-template
description: Use when creating or updating a Proxmox VM template from a distro cloud image (Ubuntu, Debian, Fedora, Rocky, etc.) with cloud-init, or when a clone from such a template misbehaves (no SSH key, no IP, guest agent missing, tiny root disk). Covers qm disk import naming on directory vs LVM/ZFS storage.
---

# Proxmox Cloud-Init Template

## Overview

Cloud images are pre-installed disks that configure themselves on first boot via cloud-init.
Import one into a VM, attach a cloud-init drive, set defaults, then `qm template`.
Clones inherit everything — to provision a VM from the template, use the `provisioning-vms` skill.

Run everything **on the Proxmox node** as root.

## Homelab conventions

| Item | Value |
|---|---|
| Node | `methionine` |
| Image storage | `adenine` (directory storage, `/mnt/adenine`) |
| Template VMIDs | 9000–9099 (`9000` = `ubuntu-cloud-26-04`) |
| Bridge | `vmbr0` |

Record each new template in the table at the bottom of this file.

## Image sources

| Distro | URL pattern | Guest agent in image? |
|---|---|---|
| Ubuntu | `https://cloud-images.ubuntu.com/<codename>/current/<codename>-server-cloudimg-amd64.img` | **No** |
| Debian | `https://cloud-images.debian.org/images/cloud/<codename>/latest/debian-<ver>-genericcloud-amd64.qcow2` | Yes |
| Fedora | `https://download.fedoraproject.org/pub/fedora/linux/releases/<ver>/Cloud/x86_64/images/` | Yes |
| Rocky | `https://dl.rockylinux.org/pub/rocky/<ver>/images/x86_64/Rocky-<ver>-GenericCloud-Base.latest.x86_64.qcow2` | Yes |

Verify checksum **before** any virt-customize (it modifies the image):
```bash
wget <url>/SHA256SUMS && sha256sum -c SHA256SUMS --ignore-missing
```

## Procedure

```bash
VMID=9001; NAME=debian-13-cloud; STORAGE=adenine; IMG=debian-13-genericcloud-amd64.qcow2

wget https://cloud-images.debian.org/images/cloud/trixie/latest/$IMG
# Ubuntu only: bake in the guest agent (once: apt install -y libguestfs-tools)
# export LIBGUESTFS_BACKEND=direct   # required on Proxmox (no libvirt)
# virt-customize -a $IMG --install qemu-guest-agent --run-command 'systemctl enable qemu-guest-agent'

# 1. VM shell must exist BEFORE import ("Configuration file ... does not exist" otherwise)
qm create $VMID --name $NAME --memory 4096 --cores 4 --cpu host --ostype l26 \
  --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci

# 2. Import. Prints "unused0: successfully imported disk '<VOLID>'" — copy VOLID exactly.
#    Directory storage: add --format qcow2 (thin). LVM-thin/ZFS: omit, always raw.
qm disk import $VMID $IMG $STORAGE --format qcow2

# 3. Attach using the VOLID from step 2 (format differs by storage type, see below)
qm set $VMID --scsi0 $STORAGE:$VMID/vm-$VMID-disk-0.qcow2,discard=on,ssd=1   # directory
# qm set $VMID --scsi0 $STORAGE:vm-$VMID-disk-0,discard=on,ssd=1            # lvm-thin/zfs

# 4. Cloud-init drive, boot order, serial console, guest agent
qm set $VMID --ide2 $STORAGE:cloudinit
qm set $VMID --boot order=scsi0
qm set $VMID --serial0 socket --vga serial0
qm set $VMID --agent enabled=1,fstrim_cloned_disks=1

# 5. Cloud-init defaults (clones/tofu can override)
qm set $VMID --ciuser fahim --sshkeys ~/.ssh/id_ed25519.pub --ipconfig0 ip=dhcp --ciupgrade 1

# 6. Grow root disk; cloud-init growpart expands fs on first boot
qm disk resize $VMID scsi0 20G

# 7. Template, cleanup
qm template $VMID
rm $IMG

```

## Volume ID naming (the gotcha)

Storage type decides the VOLID format for `--scsi0`. Directory storage needs `vmid/filename.ext`:

| Storage type | VOLID |
|---|---|
| Directory / NFS (`adenine`) | `adenine:9000/vm-9000-disk-0.raw` (or `.qcow2`) |
| LVM-thin / ZFS (`local-lvm`, `local-zfs`) | `local-lvm:vm-9000-disk-0` |

Errors when wrong: `unable to parse directory volume name` / `unable to parse volume filename`.
Never guess — use the VOLID printed by `qm disk import`.

## Common mistakes

| Symptom | Cause / fix |
|---|---|
| `Configuration file ... does not exist` on import | `qm create` first |
| `qm importdisk` | Deprecated alias; use `qm disk import` |
| Raw 3.5G disk on directory storage | Omitted `--format qcow2`; raw is fully allocated, no thin |
| Clone has tiny root fs | Resize **before** `qm template` (or `qm disk resize` on clone) |
| Agent shows "not running" on Ubuntu clone | Image lacks `qemu-guest-agent`; virt-customize or cloud-init `packages:` snippet |
| No IP on clone | `--ipconfig0 ip=dhcp` not set; cloud-init defaults to no network config |
| Can't SSH | `--sshkeys` path must be readable by root on node; user is `--ciuser`, not `root`/`ubuntu` |
| Changed cloud-init settings not applied | `qm cloudinit update <vmid>` then reboot; only applies on first boot unless instance-id changes |
| Template in use by tofu | Re-creating same VMID breaks linked clones; use new VMID, bump `clone.vm_id` |

## Provisioning VMs from a template

Use the `provisioning-vms` skill (OpenTofu `bpg/proxmox`).

## Templates on methionine

| VMID | Name | Image | Created |
|---|---|---|---|
| 9000 | ubuntu-cloud-26-04 | resolute-server-cloudimg-amd64.img (raw, no guest agent) | 2026-08-29 |
