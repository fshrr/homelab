# GitOps Tool Selection — Spike

**Date:** 2026-05-31
**Status:** Complete
**Author:** Claude Code

## Context
Moving from Docker Compose + Ansible deploy to Kubernetes requires a GitOps tool to manage cluster state declaratively from git. Evaluated FluxCD and ArgoCD.

## Questions
- [x] FluxCD vs ArgoCD — which fits homelab + career goals?
- [x] How does each handle multi-cluster?
- [x] Resource overhead on single-node Proxmox?

## Findings

Both are CNCF Graduated projects. Both support Helm and Kustomize natively.

**FluxCD:** Distributed controllers (~300MB RAM), no built-in UI, pure pull model. Many composable CRDs (GitRepository, HelmRelease, Kustomization). Lighter, simpler operations. Better for experienced K8s users.

**ArgoCD:** Monolithic server (~1-1.5GB RAM), rich built-in web UI, pull with optional push. Main CRD is `Application` + `ApplicationSet` for templating. UI shows resource topology, sync diffs, rendered Helm output.

**Multi-cluster:** FluxCD uses per-cluster controllers (each node self-manages). ArgoCD centralizes management with ApplicationSet for fleet templating. Both work well at homelab scale (<10 clusters).

**Learning value:** ArgoCD's UI provides visual feedback loops critical for learning K8s — shows resource relationships, sync failures, drift, and rendered Helm manifests. FluxCD requires CLI knowledge to get same info.

## Options

### Option A: FluxCD
**How it works:** Bootstrap with `flux bootstrap github`. Controllers watch git repo paths, reconcile automatically.
**Pros:** Light resource footprint, invisible after setup, stronger multi-tenancy, more "infrastructure engineer" approach.
**Cons:** No UI — harder to learn K8s object model, Helm is a black box unless manually templated.

### Option B: ArgoCD
**How it works:** Install via Helm, manage apps through UI or `Application` CRDs. App-of-apps pattern for bootstrapping.
**Pros:** UI accelerates K8s learning, shows rendered Helm output, visual topology and drift detection, strong interview demo material, ApplicationSet for multi-cluster.
**Cons:** ~1GB more RAM, operational overhead maintaining ArgoCD itself (upgrades, RBAC, ingress for UI).

## Recommendation
Option B: ArgoCD. Learning value outweighs resource cost for someone new to self-managed K8s. UI provides visual feedback loop that accelerates building mental models of K8s resource relationships. Maintaining ArgoCD itself teaches real K8s operational patterns. Can migrate to FluxCD later if overhead becomes a concern.

`→ decisions/argocd.md`

## Out of Scope
- ArgoCD configuration details (implementation)
- SSO/RBAC setup for ArgoCD UI
- App-of-apps pattern specifics
