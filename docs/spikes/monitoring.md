# Kubernetes Monitoring Stack — Spike

**Date:** 2026-05-31
**Status:** Complete
**Author:** Claude Code

## Context
Currently running Prometheus + Grafana + node_exporter for monitoring Docker Compose services. Moving to Kubernetes — need to evaluate whether to keep this stack or adopt a more K8s-native monitoring solution.

## Questions
- [ ] Is Prometheus/Grafana still the best choice for K8s?
- [ ] Are there lighter or more integrated alternatives?
- [ ] What about logging and tracing (not just metrics)?

## Findings

### Current Stack: Prometheus + Grafana
Works well for K8s — `kube-prometheus-stack` Helm chart bundles Prometheus Operator, Grafana, Alertmanager, node_exporter, kube-state-metrics, and pre-built K8s dashboards. Industry standard.

### Full Observability (Metrics + Logs + Traces)

K8s monitoring is more than metrics. Three pillars:

| Pillar | Current | K8s Options |
|---|---|---|
| **Metrics** | Prometheus + Grafana | Prometheus, Victoria Metrics, Mimir |
| **Logs** | None (docker compose logs) | Loki, OpenSearch, Elasticsearch |
| **Traces** | None | Tempo, Jaeger |

## Options

### Option A: kube-prometheus-stack (Prometheus + Grafana)
**How it works:** Helm chart deploys Prometheus Operator, Grafana, Alertmanager with pre-configured K8s dashboards. ServiceMonitor/PodMonitor CRDs for scrape targets.
**Pros:** Industry standard, massive community, pre-built dashboards, familiar (already using it), every K8s guide assumes Prometheus.
**Cons:** Prometheus RAM usage grows with metric cardinality, no built-in logs/traces, need Loki/Tempo separately.

### Option B: Grafana Stack (Prometheus + Loki + Tempo + Alloy)
**How it works:** Full observability platform. Alloy (formerly Grafana Agent) collects and ships metrics/logs/traces. Loki for logs, Tempo for traces, Prometheus for metrics. All visualized in Grafana.
**Pros:** Unified observability, single UI (Grafana), correlate metrics/logs/traces, Loki is lightweight for logs.
**Cons:** More components to deploy and maintain, heavier resource usage.

### Option C: Victoria Metrics
**How it works:** Drop-in Prometheus replacement. Compatible with PromQL, Prometheus scrape configs, and Grafana.
**Pros:** Significantly less RAM and disk than Prometheus (up to 7x), faster queries, long-term storage built-in, single binary option.
**Cons:** Smaller community than Prometheus, some PromQL edge cases differ, less K8s-specific tooling.

### Option D: Hubble (Cilium) + Prometheus/Grafana
**How it works:** Cilium's Hubble provides network-layer observability (traffic flows, DNS, HTTP metrics). Combine with Prometheus for app/system metrics.
**Pros:** Free network observability from CNI choice (Cilium already decided), no extra agent for network metrics, Hubble UI for traffic visualization.
**Cons:** Only covers network layer — still need Prometheus for app/system metrics.

### Option E: Pixie (eBPF-based)
**How it works:** eBPF-based auto-instrumentation. No code changes, captures requests, CPU profiles, network traffic automatically.
**Pros:** Zero instrumentation needed, protocol-level visibility, auto-discovers services.
**Cons:** Acquired by New Relic (open source but uncertain future), higher resource usage, less mature.

## Recommendation
Prometheus + Grafana + Loki + Hubble. Specifically:

- **kube-prometheus-stack** — metrics, dashboards, alerting
- **Loki** — log aggregation (lightweight, pairs with Grafana natively)
- **Hubble** — network observability (free from Cilium, no extra deployment)
- **Grafana** — unified UI for all three

Hubble exports metrics to Prometheus and has pre-built Grafana dashboards. All three pillars visible in one place.

`→ decisions/monitoring-stack.md`

## Out of Scope
- Alerting strategy (PagerDuty, Slack, etc.)
- Specific Grafana dashboard selection
- Log retention policies
