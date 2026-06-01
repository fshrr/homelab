# Talos Linux for Kubernetes Nodes — Spike

**Date:** 2026-05-31
**Status:** Complete
**Author:** Claude Code

## Context
Homelab runs Docker Compose services on Debian LXC containers in Proxmox. Migration to Kubernetes requires a host OS for K8s nodes. Evaluated whether to run K8s on Debian (via k3s/kubeadm) or use a purpose-built K8s OS.

## Questions
- [x] What OS should K8s nodes run?
- [x] Can we keep LXC for GPU-bound workloads?
- [x] How does this affect horizontal scaling?

## Findings

Talos Linux is an immutable, API-managed OS purpose-built for Kubernetes. No SSH, no shell, no package manager — managed entirely via `talosctl` and machine config YAML files. Runs as VMs on Proxmox.

Key finding: LXC containers remain for GPU-bound workloads (Jellyfin) since `/dev/dri/renderD128` can be shared across LXC containers but VMs monopolize it. Hybrid model: Talos VMs for K8s + LXC for GPU services.

Talos machine configs are portable IaC — same configs provision nodes on Proxmox, cloud VPS, or mini PCs. Enables horizontal scaling by adding Talos nodes anywhere that auto-join the cluster.

## Options

### Option A: Talos Linux on Proxmox VMs
**How it works:** OpenTofu provisions Talos VMs via `bpg/proxmox`. Talos machine configs define node identity, cluster membership, CNI, etc. No Ansible needed for node management.
**Pros:** Immutable (no drift), API-managed, eliminates Ansible for nodes, portable across hardware/cloud, secure by default (no SSH attack surface).
**Cons:** Heavier resource use than LXC, requires learning `talosctl`, GPU passthrough to VM means only one VM gets GPU.

### Option B: k3s on Debian VMs
**How it works:** OpenTofu provisions Debian VMs, Ansible installs k3s.
**Pros:** Familiar Linux, SSH access for debugging, lighter learning curve.
**Cons:** Mutable OS = config drift risk, still need Ansible for node management, less portable.

### Option C: k3s on LXC
**How it works:** K8s runs inside LXC containers directly.
**Pros:** Lightest resource use, keeps GPU sharing model.
**Cons:** Fragile — K8s in LXC has cgroup/kernel quirks, not production-grade pattern.

## Recommendation
Option A: Talos Linux. Eliminates config drift, removes Ansible dependency for nodes, and machine configs as IaC enable scaling to cloud/mini PCs trivially. GPU workloads stay on LXC outside the cluster.

`→ decisions/talos-linux.md`

## Out of Scope
- Specific Talos machine config structure (implementation detail)
- Cloud provider selection for remote nodes
