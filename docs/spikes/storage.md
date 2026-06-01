# Kubernetes Storage — Spike

**Date:** 2026-05-31
**Status:** Complete
**Author:** Claude Code

## Context
Proxmox host has a ZFS pool storing media locally. App config currently lives at `/mnt/docker/<service>/`. Moving to Kubernetes — need PersistentVolume strategy for both app data and media. Multi-node planned soon.

## Questions
- [x] Which CSI driver(s) to use?
- [x] Do we need distributed/replicated storage?
- [x] How to handle media storage in K8s?
- [ ] Backup strategy (currently Restic to Mega.nz — separate spike)

## Findings

Two distinct storage needs:
1. **App config/data** — small, per-service (Sonarr config, Immich DB). Needs persistence, backup, and replication when multi-node.
2. **Media** — large, shared across services (movies, shows, photos). Lives on Proxmox ZFS pool locally.

Key finding: media is on the Proxmox host's ZFS pool, not a separate NAS. NFS adds unnecessary network hop on single node. Direct mount via virtio disk or virtiofs passthrough is faster and simpler.

NFS becomes necessary only when remote nodes (mini PCs, VPS) need access to media — at that point Proxmox exports the ZFS pool via NFS.

## Options

### Option A: Longhorn (app data) + Direct mount (media)
**How it works:** Longhorn manages app config/data with replication. Media mounted directly from Proxmox ZFS into Talos VM via virtio/virtiofs.
**Pros:** Replicated app data (ready for multi-node), snapshots + backup-to-S3 from day one, fastest media access (no network hop), clean separation of concerns.
**Cons:** Longhorn overhead (~500MB RAM), replication doesn't help until second node arrives.

### Option B: NFS CSI Driver Only
**How it works:** Everything on NFS — Proxmox exports ZFS pool.
**Pros:** Simple, one storage backend.
**Cons:** Unnecessary network hop for local VM, bad for database I/O, no replication, no snapshots.

### Option C: OpenEBS LocalPV (app data) + Direct mount (media)
**How it works:** LocalPV wraps host paths as PersistentVolumes. Simple, fast, zero overhead.
**Pros:** Dead simple, near-zero resource usage.
**Cons:** No replication, no snapshots, requires migration to Longhorn later for multi-node.

## Recommendation
Option A: Longhorn + direct mount. Multi-node planned soon — start with Longhorn now to avoid migration later. Snapshots and backup-to-S3 are useful even on single node. Media stays on direct mount for performance; add NFS export from Proxmox when remote nodes arrive.

`→ decisions/storage.md`

## Out of Scope
- Proxmox ZFS pool configuration
- NFS server setup (deferred until multi-node)
- Backup tool selection (Velero vs Restic — separate spike)
- virtiofs vs virtio disk passthrough details
