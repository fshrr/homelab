# OpenTofu for Infrastructure Provisioning — Spike

**Date:** 2026-05-31
**Status:** Complete
**Author:** Claude Code

## Context
OpenTofu with `bpg/proxmox` provider already provisions LXC containers. With the move to Kubernetes on Talos Linux, OpenTofu's role expands to provisioning Talos VMs on Proxmox and potentially cloud VMs for remote K8s nodes.

## Questions
- [x] Does OpenTofu stay in the stack?
- [x] How does scope change with K8s migration?

## Findings

OpenTofu remains the right tool for infrastructure provisioning. Role changes:

**Before (Docker Compose era):**
- Provision Debian LXC containers on Proxmox
- Output IPs for Ansible inventory

**After (Kubernetes era):**
- Provision Talos Linux VMs on Proxmox
- Provision LXC containers for GPU-bound workloads (Jellyfin)
- Potentially provision cloud VMs (Hetzner, Oracle, etc.) for remote Talos nodes
- Generate Talos machine configs or feed outputs to `talosctl`
- State stored in Cloudflare R2 bucket (unchanged)

Ansible's role shrinks significantly — no longer needed for K8s node management (Talos handles itself). Ansible only needed for LXC workloads.

## Recommendation
Keep OpenTofu. Expand scope from LXC-only to Talos VMs + LXC + cloud providers. No alternative needed — OpenTofu is the right tool for declarative infrastructure provisioning.

## Out of Scope
- Specific cloud provider selection
- Talos VM resource sizing
- OpenTofu module structure for multi-provider
