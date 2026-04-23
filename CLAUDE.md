# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a homelab infrastructure-as-code repository managing Docker Compose services running on a host named **bromine** (Tailscale address: `bromine.fenrir-cardassian.ts.net`). Services are accessible internally via Tailscale and externally via Traefik reverse proxy at `*.homelab.fahimshahreer.com` (and some at `*.fahimshahreer.com`).

## Common Operations

Deploy or update a service stack:
```bash
cd docker/<service>
docker compose up -d
```

Bring down a stack:
```bash
docker compose down
```

View logs:
```bash
docker compose logs -f [service-name]
```

Create required Docker networks (run once on a new host):
```bash
bash scripts/docker_networks.sh
```

Create an NFS-backed Docker volume:
```bash
bash scripts/create_docker_nfs_volume.sh <volume-name> <nfs-device-path>
# NFS server is at 192.168.2.120
```

Bootstrap a new Debian 13 LXC container:
```bash
bash scripts/lxc_deb_start.sh
```

## Architecture

### Directory Layout

- `docker/` — one subdirectory per service stack, each with its own `docker-compose.yml` (or `.yaml`) and `.env.example`
- `docker/base.yml` — shared base service with common env vars (`PUID=1001`, `PGID=1001`, `TZ=America/Toronto`); stacks extend this via `extends:`
- `scripts/` — utility shell scripts for host/infrastructure setup

### Docker Networks

Four networks defined in `scripts/docker_networks.sh` must exist before deploying:

| Network | Purpose |
|---|---|
| `traefik` | Services that need external HTTPS routing via Traefik |
| `arr` | Internal communication between *arr stack and downloaders |
| `arr-seerr` | Connects arr services to media request managers |
| `docker-socket-proxy` | Traefik and Homepage access Docker API safely |

### Traefik Reverse Proxy (`docker/traefik/`)

- Traefik v3.2 handles TLS termination and HTTP→HTTPS redirects
- Certificates obtained via Cloudflare DNS challenge (wildcard for `*.homelab.fahimshahreer.com`)
- Traefik reads Docker labels through `docker-socket-proxy` (not direct socket mount) for security
- Services opt in with `traefik.enable=true` labels and must be on the `traefik` network
- The `cf-dns-resolver` certresolver is set as the default for `websecure`, so individual services don't need to specify it

### Storage Conventions

- App config/data: `/mnt/docker/<service>/` on the host (or named Docker volumes for some)
- Media: NFS-mounted paths; paths are injected via `.env` files using variables like `MOVIES_PATH`, `SHOWS_PATH`, etc.
- Backups: Restic backs up `/mnt/docker` daily at 6am to Mega.nz via rclone; restore via `/mnt/backup-restore`

### Adding a New Service

1. Create `docker/<service>/docker-compose.yml`
2. Copy `.env.example` pattern if env vars are needed
3. Add `extends: file: ../base.yml` if the service needs standard `PUID`/`PGID`/`TZ`
4. For Traefik routing, add the service to the `traefik` network and include Traefik labels
5. For Homepage integration, add `homepage.*` labels (group, name, icon, href)

### Homepage Dashboard (`docker/homepage/`)

Homepage auto-discovers services via Docker labels through the `docker-socket-proxy` network. All services include `homepage.group`, `homepage.name`, `homepage.icon`, and `homepage.href` labels for dashboard integration.

### Key Services

| Stack | Directory | Notes |
|---|---|---|
| Traefik | `docker/traefik/` | Reverse proxy + TLS |
| Arr suite | `docker/arr/` | Radarr, Sonarr, Bazarr, Prowlarr, torrent/usenet clients, Recyclarr |
| Jellyfin | `docker/jellyfin/` | Media server with hardware transcoding (`/dev/dri/renderD128`) |
| Immich | `docker/immich/` | Photo management; has its own internal `immich` network + Postgres/Redis/ML |
| MediaManager | `docker/mediamanager/` | Media request manager; bridges `traefik` and `arr` networks |
| Restic | `docker/restic/` | Backup via rclone to Mega.nz |
| Cloudflare DDNS | `docker/cloudflare-ddns/` | Dynamic DNS updater |
| Prometheus/Grafana | `docker/prometheus/` | Monitoring stack with node_exporter |
