---
name: provisioning-vms
description: Use when creating a VM from a Proxmox cloud-init template with OpenTofu (bpg/proxmox), or when a cloned VM misbehaves — apply hangs waiting for guest agent, no IP output, wrong cloud-init user/key, unexpected inherited devices, or tofu wants to rebuild the clone. Covers proxmox_cloned_vm vs the legacy clone block.
---

# Provisioning VMs

**REQUIRED BACKGROUND:** proxmox-cloud-template skill — how the source template is built and which defaults (user, SSH key, DHCP, guest agent) are baked into it.

## Overview

Templates live **outside** tofu state: built by hand via the template skill, referenced by numeric `source_vm_id`. Tofu owns clones only. A **full clone** copies the disks — after apply it has no runtime dependency on the template (delete template, clone keeps running) — but the template must exist whenever tofu re-creates the VM. A **linked clone** (`full = false`) references the template's base disk forever: template pinned, same storage, thin-capable storage only.

Provider: `bpg/proxmox` (see `infra/tofu/versions.tf`).

## Picking the resource

| Need | Resource |
|---|---|
| Clone that trusts template defaults (user/key/DHCP baked in) | `proxmox_cloned_vm` (default choice) |
| Per-VM cloud-init: static IP, different user/keys, DNS | `proxmox_virtual_environment_vm` + `clone {}` block |

**`proxmox_cloned_vm` is experimental and manages only a subset of config.** It does NOT manage cloud-init, guest agent, BIOS/machine, boot order, EFI/TPM, or passthrough devices — all inherited from the template. If you need to override any of those per-VM, use the legacy resource.

## Default pattern: `proxmox_cloned_vm`

Attribute-map syntax (`=`), not blocks. Only attributes you set are managed; everything else inherits from the template and tofu leaves it alone.

```terraform
resource "proxmox_cloned_vm" "code_box" {
  node_name = var.proxmox_node
  name      = "code-box"          # becomes cloud-init hostname
  id        = 112                 # VMID; omit to let Proxmox auto-assign
  tags      = ["tofu"]

  clone = {
    source_vm_id     = 9000       # template registry: proxmox-cloud-template skill
    full             = true
    target_datastore = "adenine"  # optional; omit = same storage as template
  }

  cpu    = { cores = 4, type = "host" }
  memory = { size = 4096 }

  # Manage the NIC only if it must differ from the template
  # network = { net0 = { bridge = var.proxmox_bridge, model = "virtio" } }

  # Grow root disk (templates from the template skill use scsi0; grow only — shrink impossible)
  # disk = { scsi0 = { size_gb = 32 } }

  stop_on_destroy = true
  # delete = { disk = ["ide3"] }  # drop devices inherited from the template
}

output "code_box_id" { value = proxmox_cloned_vm.code_box.id }
```

User, SSH key, and DHCP come from the template's `--ciuser/--sshkeys/--ipconfig0` — set them there (template skill step 5).

## Fallback: legacy resource with per-VM cloud-init

```terraform
resource "proxmox_virtual_environment_vm" "code_box" {
  name      = "code-box"
  vm_id     = 112
  node_name = var.proxmox_node

  clone {
    vm_id = 9000
    full  = true
  }

  agent {
    enabled = true                # false if the template lacks qemu-guest-agent!
  }
  stop_on_destroy = true

  cpu {
    cores = 4
    type  = "host"
  }
  memory {
    dedicated = 4096
  }
  network_device {
    bridge = var.proxmox_bridge
  }

  initialization {
    datastore_id = "adenine"      # replaces the inherited cloud-init drive
    ip_config {
      ipv4 {
        address = "192.168.2.150/24"
        gateway = "192.168.2.1"
      }
    }
    user_account {
      username = "fahim"
      keys     = [var.ssh_public_key]
    }
  }
}
```

## Gotchas

| Symptom | Cause / fix |
|---|---|
| Apply hangs, then "error waiting for agent" | Template has no qemu-guest-agent (check registry in template skill). `agent { enabled = false }`, or rebuild template with agent baked in. `proxmox_cloned_vm` doesn't manage agent at all — inherits template setting. |
| `ipv4_addresses` output empty/fails | Needs a *running* agent in the guest. Index is per-interface: `ipv4_addresses[1][0]` skips `lo`. |
| Wrong user / key on clone | `proxmox_cloned_vm` can't set cloud-init: fix template defaults, or switch to legacy resource with `initialization`. |
| Plan wants to destroy/recreate on template rebuild | `source_vm_id` unchanged is fine; recreating template under a *new* VMID means updating `source_vm_id` → forces replacement. Plan clone rebuilds deliberately. |
| Need VM's IP from tofu | `proxmox_cloned_vm` exposes no `ipv4_addresses` — use the legacy resource with a working agent, or DHCP reservation / DNS. |
| Linked clone refuses storage | `full = false` needs thin-capable storage shared with template; full clone anywhere. |
| Destroy hangs on running VM | Set `stop_on_destroy = true` (both resources). |
| Static IP needed but using `proxmox_cloned_vm` | Not supported there; legacy resource `initialization.ip_config`, or `qm set <vmid> --ipconfig0 ip=...` out-of-band (drifts outside tofu). |

## Homelab conventions

Node `methionine`; vars `proxmox_node`, `proxmox_bridge` in `infra/tofu/variables.tf`. VMIDs: 9000–9099 templates (registry in proxmox-cloud-template skill), 100–199 VMs. Current template 9000 (`ubuntu-cloud-26-04`) has **no guest agent** — agent-dependent features fail until it's rebuilt.

Ansible post-provisioning: not yet — add here once `infra/ansible/` exists.
