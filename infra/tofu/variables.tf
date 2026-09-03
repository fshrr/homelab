# --- Provider auth (values come from Infisical via `infisical run --path=/proxmox`) ---

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint, e.g. https://192.168.2.10:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "API token string: tofu@pve!provider=<secret>"
  type        = string
  sensitive   = true
}

# --- Shared placement (defaults match the current infra) ---

variable "proxmox_node" {
  description = "Proxmox node that hosts the VMs"
  type        = string
  default     = "methionine"
}

variable "proxmox_bridge" {
  description = "Network bridge for the VM NICs"
  type        = string
  default     = "vmbr0"
}

variable "talos_datastore" {
  description = "Datastore for Talos VM boot disks"
  type        = string
  default     = "vms1"
}

variable "talos_iso_file_id" {
  description = "Volume id of the Talos ISO"
  type        = string
  default     = "adenine:iso/metal-amd64.iso"
}
