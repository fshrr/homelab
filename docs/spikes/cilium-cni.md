# CNI Selection — Spike

**Date:** 2026-05-31
**Status:** Complete
**Author:** Claude Code

## Context
Kubernetes requires a Container Network Interface (CNI) plugin to handle pod networking — IP allocation, pod-to-pod communication, network policies, and optionally load balancing and ingress. CNI is the networking layer that replaces Docker networks in the K8s world.

## Questions
- [x] What CNI to use?
- [x] What is CNI? (networking layer for K8s pods — assigns IPs, routes traffic, enforces network policies)

## Findings

Three main options for homelab K8s:

**Flannel:** Simplest CNI. VXLAN overlay networking. No network policies. Fine for basic setups but limited.

**Calico:** Mature, supports network policies, BGP peering. Good middle ground. Widely used in enterprise.

**Cilium:** eBPF-based networking. Replaces kube-proxy, handles network policies, load balancing, observability (Hubble), and can serve as ingress/gateway via Gateway API. Most feature-rich. Industry direction for high-performance K8s networking, especially in AI/ML infrastructure.

## Options

### Option A: Cilium
**How it works:** eBPF programs in kernel handle networking — bypasses iptables entirely. Includes Hubble for network observability.
**Pros:** Fastest performance (eBPF), replaces kube-proxy, built-in observability (Hubble), Gateway API support (can replace Traefik), network policies, strong resume item for AI infra roles.
**Cons:** Slightly more complex initial setup, requires Linux kernel 5.10+ (Talos ships modern kernels, so no issue).

### Option B: Calico
**How it works:** Traditional iptables/IPVS networking with optional eBPF dataplane.
**Pros:** Mature, well-documented, good network policy support.
**Cons:** Less performant than Cilium, no built-in observability, iptables-based by default.

### Option C: Flannel
**How it works:** Simple VXLAN overlay.
**Pros:** Simplest to set up, lowest learning curve.
**Cons:** No network policies, no observability, limited features.

## Recommendation
Option A: Cilium. eBPF-based networking is the industry direction, Hubble provides free network observability, and it's directly relevant to AI infrastructure roles (Tenstorrent posting). Talos ships compatible kernels. Gateway API support may allow consolidating ingress later.

`→ decisions/cilium-cni.md`

## Out of Scope
- Whether to replace Traefik with Cilium Gateway API (separate decision)
- Cilium configuration specifics
- Hubble dashboard setup
