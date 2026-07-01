# Secrets Management for Kubernetes — Spike

**Date:** 2026-05-31
**Status:** Complete
**Author:** Claude Code

## Context
Infisical already serves as the secrets manager for the homelab (Infisical Cloud — the managed SaaS, not self-hosted). With the move to Kubernetes, secrets need to flow from Infisical into K8s Secrets objects. Evaluated whether to keep Infisical or switch.

## Questions
- [x] Does Infisical work with Kubernetes?
- [x] Is HashiCorp Vault a better option?
- [x] How do secrets get into K8s?

## Findings

**Infisical + K8s:** Infisical has an official Kubernetes operator and works with External Secrets Operator (ESO). ESO creates K8s Secrets from Infisical entries automatically — pods reference secrets normally, ESO keeps them synced.

**HashiCorp Vault:** Vault changed to BSL (Business Source License) in August 2023. OpenBao is the open-source fork under Linux Foundation, but it's younger and has less ecosystem support. Vault is more powerful (dynamic secrets, PKI, transit encryption) but significantly more complex to operate — overkill for homelab.

**Flow:** Infisical (source of truth) → External Secrets Operator (syncs to K8s) → K8s Secrets (consumed by pods)

## Options

### Option A: Infisical + External Secrets Operator
**How it works:** ESO deployed in K8s, configured with Infisical provider. `ExternalSecret` CRDs define which secrets to sync. ESO creates/updates K8s Secrets automatically.
**Pros:** Already use Infisical Cloud, ESO is CNCF project, no migration needed, simple to operate, no self-hosted secrets instance to maintain.
**Cons:** ESO adds another component to maintain.

### Option B: HashiCorp Vault
**How it works:** Deploy Vault (or OpenBao), use Vault Agent Injector or CSI driver for K8s integration.
**Pros:** Industry standard, dynamic secrets, powerful PKI.
**Cons:** BSL license (Vault) or immature fork (OpenBao), complex to operate, overkill for homelab, would require migrating all secrets from Infisical.

### Option C: Sealed Secrets
**How it works:** Encrypt secrets in git with a cluster-side controller that decrypts them.
**Pros:** Secrets live in git (encrypted), simple model.
**Cons:** Cluster-scoped key management, no central secrets UI, doesn't replace Infisical for non-K8s secrets.

## Recommendation
Option A: Keep Infisical, add External Secrets Operator. Already invested in Infisical Cloud (SaaS), works well, ESO integration is straightforward. No reason to migrate.

`→ decisions/infisical-eso.md`

## Out of Scope
- ESO configuration details
- Infisical operator vs ESO (ESO is more flexible and provider-agnostic)
