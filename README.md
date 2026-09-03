# homelab

Self-hosted infrastructure running on Proxmox across multiple hosts. Services are deployed on Kubernetes (Talos Linux VMs) and LXC containers, managed declaratively with OpenTofu, ArgoCD, and Ansible. Internal access via Tailscale.

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  Infisical Cloud (SaaS) — secrets source of truth            │
│  External Secrets Operator syncs them into K8s Secrets       │
└──────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                      Proxmox Hosts                           │
│                                                              │
│  ┌───────────────────────────┐  ┌──────────────────────────┐ │
│  │     Talos Linux VMs       │  │    LXC Containers        │ │
│  │                           │  │    (GPU workloads)       │ │
│  │  ┌─────────────────────┐  │  │                          │ │
│  │  │    Kubernetes       │  │  │  Jellyfin                │ │
│  │  │                     │  │  │  /dev/dri/renderD128     │ │
│  │  │  Cilium (CNI)       │  │  │                          │ │
│  │  │  ArgoCD (GitOps)    │  │  └──────────────────────────┘ │
│  │  │  Longhorn (storage) │  │                               │
│  │  │  ESO (secrets)      │  │                               │
│  │  └─────────────────────┘  │                               │
│  └───────────────────────────┘                               │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  ZFS Pool — media storage (virtio/virtiofs to VMs)      │ │
│  └─────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

| Layer | Tool | Role |
|---|---|---|
| Node OS | Talos Linux | Immutable, API-managed K8s OS — no SSH, no config drift |
| Provisioning | OpenTofu + `bpg/proxmox` | Talos VMs, LXC containers, future cloud nodes |
| Networking | Cilium | eBPF CNI, replaces kube-proxy, Gateway API, Hubble observability |
| GitOps | ArgoCD | Declarative cluster state from git, UI for resource topology |
| Secrets | Infisical Cloud + External Secrets Operator | Infisical Cloud as source of truth, ESO syncs into K8s Secrets |
| Storage (apps) | Longhorn | Replicated PVs with snapshots and S3 backup |
| Storage (media) | Direct ZFS mount | virtio/virtiofs from Proxmox ZFS, NFS for remote nodes |
| Monitoring | Prometheus + Grafana + Loki + Hubble | Metrics, logs, network observability — unified in Grafana |
| CI/CD | GitHub Actions | `tofu plan` on PR, `tofu apply` on merge |

## Repository Structure

```
homelab/
├── docker/                        # Docker Compose service stacks
│   ├── base.yml                   # Shared env vars (PUID, PGID, TZ)
│   └── <service>/
│       ├── docker-compose.yml
│       └── .env.example
│
├── k8s/                           # Kubernetes manifests and Helm values
│
├── infra/
│   ├── tofu/                      # OpenTofu — Proxmox VM/LXC provisioning
│   └── ansible/                   # Ansible — VM/LXC system configuration
│
├── scripts/                       # Transitional shell scripts
│
├── docs/
│   ├── index.md                   # Documentation index
│   ├── spikes/                    # Architecture spike write-ups
│   ├── decisions/                 # Architecture decision records
│   ├── plans/                     # Implementation plans
│   └── templates/                 # Spike, decision, and plan templates
│
└── .github/
    └── workflows/                 # CI/CD pipelines
```

## Services

| Service | Purpose | Status |
|---|---|---|
| Jellyfin | Media server with hardware transcoding | Docker (LXC — GPU) |
| Radarr | Movie automation | Docker |
| Sonarr | TV automation | Docker |
| Bazarr | Subtitle automation | Docker |
| Prowlarr | Indexer manager | Docker |
| Recyclarr | Quality profile sync | Docker |
| Torrent / Usenet clients | Downloaders | Docker |
| MediaManager | Media request manager | Docker |
| Immich | Photo management (Postgres, Redis, ML) | Docker |
| AudioBookshelf | Audiobook and podcast server | Docker |
| Calibre | eBook management | Docker |
| Open-WebUI | LLM chat interface | Docker |
| Hoarder | Bookmark manager | Docker |
| Vaultwarden | Bitwarden-compatible password manager | Docker |
| Actual Budget | Budgeting app | Docker |
| Omnitools | Utility tools | Docker |
| Homepage | Dashboard — auto-discovers via Docker labels | Docker |
| Prometheus + Grafana | Monitoring with node_exporter | Docker |
| Restic | Daily backup to Mega.nz via rclone | Docker |
| Cloudflare DDNS | Dynamic DNS updater | Docker |
| Infisical Cloud | Secrets source of truth | SaaS (external) |

## Architecture Decisions

| Decision | Spike | Summary |
|---|---|---|
| Node OS | [Talos Linux](docs/spikes/talos-linux.md) | Immutable, API-managed — eliminates drift, no Ansible needed for nodes |
| GitOps | [ArgoCD](docs/spikes/gitops-argocd.md) | UI accelerates K8s learning, resource topology and sync diffs |
| IaC | [OpenTofu](docs/spikes/opentofu-iac.md) | Scope expands from LXC-only to Talos VMs + cloud providers |
| Secrets | [Infisical Cloud + ESO](docs/spikes/secrets-management.md) | Use Infisical Cloud, add External Secrets Operator for K8s |
| CNI | [Cilium](docs/spikes/cilium-cni.md) | eBPF networking, replaces kube-proxy, Hubble observability |
| Monitoring | [Prometheus + Loki + Hubble](docs/spikes/monitoring.md) | kube-prometheus-stack + Loki + Hubble, unified in Grafana |
| Storage | [Longhorn + direct mount](docs/spikes/storage.md) | Longhorn for app data, direct ZFS mount for media |

## Scripts

Transitional — will be replaced by Ansible roles and OpenTofu.

- `scripts/lxc_deb_start.sh` — bootstrap a new Debian LXC container
- `scripts/vm_deb_start.sh` — bootstrap a new Debian VM
- `scripts/docker_networks.sh` — create required Docker networks
