# Kubernetes cluster topology (v1) — Decision

**Date:** 2026-07-01
**Status:** Accepted
**Related:** [Talos Linux spike](../spikes/talos-linux.md), [Storage spike](../spikes/storage.md), [Cilium spike](../spikes/cilium-cni.md)

## Context

The Talos spike settled the node OS but explicitly left machine-config and node
topology out of scope. Before the first cluster can be provisioned we need an
initial topology: how many control-plane nodes, how many workers, and how roles
are split.

Constraints:

- **Single physical host** — everything runs on `bromine` (one Proxmox host)
  today. Any multi-node control plane on one box is practice, not real HA: the
  host is still a single point of failure.
- **Goal is learning production-grade self-managed K8s** (platform-eng track),
  balanced against a "one thing at a time" scope discipline.
- **GPU workloads stay on LXC** — Jellyfin keeps `/dev/dri/renderD128` on an LXC
  container outside the cluster, per the Talos spike.

## Decision

Start with **1 dedicated control plane + 1 worker**, both Talos VMs on `bromine`.

| Node | Role | Taint | Runs |
|---|---|---|---|
| `talos-cp-01` | control plane | `node-role.kubernetes.io/control-plane:NoSchedule` | etcd, API server, scheduler, controller-manager only (single-node etcd, no quorum) |
| `talos-wn-01` | worker | none | all application workloads |

**Sizing (defaults, adjustable to `bromine` headroom):**

| Node | vCPU | RAM | Disk |
|---|---|---|---|
| `talos-cp-01` | 2 | 4 GB | 32 GB (etcd is small) |
| `talos-wn-01` | 6 | 16 GB | 40 GB OS + dedicated SSD-backed virtual disk for Longhorn |

**Storage split:**

- **App data** → Longhorn PVs on **SSD-backed Proxmox storage**. Replica count = 1
  (only one storage node), so snapshots + S3 backup, no live replication yet.
- **Media** → direct ZFS mount (virtio/virtiofs) into the worker, per the storage
  spike. Not Longhorn.

**Deferred (rejected for now):** HA control plane (3 nodes), additional workers,
and cloud/multi-site nodes. HA on a single host is practice-only SPOF; cloud
control plane adds 24/7 cost and multi-site complexity not wanted yet.

## Consequences

**Easier:**

- Minimal resource use and the smallest topology that still models the real
  control-plane/worker split.
- Simple to reason about and provision (two machine configs, two roles).
- Clean scale path — new worker VMs auto-join; control-plane and cloud nodes
  bolt on later without redesign.
- Exercises taints/tolerations, control-plane isolation, and per-role Talos
  machine configs — good learning surface.

**Harder / accepted risks:**

- **No HA.** Control-plane reboot or crash = brief API/control-plane outage.
  Already-running pods keep running, but no deploys or self-healing meanwhile.
- **`bromine` is a single point of failure** for the whole cluster.
- **Longhorn replica = 1** — no live storage redundancy (snapshots + S3 backup
  only) until worker #2 exists.
- **No pod reschedule/drain practice** — nowhere to move pods until worker #2.

## Scale path

```
1 CP + 1 WN (now)
   └─ add worker VM(s)      → pod reschedule/drain, Longhorn live replicas
        └─ 3 CP for HA      → needs ≥2 physical hosts for *real* HA
             └─ cloud nodes → KubeSpan mesh, multi-site (when wanted)
```
