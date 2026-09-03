# Talos control-plane node.
# Planned static IP (set later in the Talos machine config, not here): 192.168.2.101/24
resource "proxmox_virtual_environment_vm" "talos_cp_01" {
  name      = "talos-cp-01"
  node_name = var.proxmox_node
  vm_id     = 101
  tags      = ["talos", "k8s", "controlplane"]

  # Talos runs its guest agent only once configured; keep off so the first
  # apply doesn't block waiting for it.
  agent {
    enabled = false
  }
  stop_on_destroy = true

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 4096
  }

  # Blank boot disk Talos installs onto. raw = required for lvmthin.
  disk {
    datastore_id = var.talos_datastore
    interface    = "scsi0"
    size         = 20
    file_format  = "raw"
  }

  # Boot the Talos ISO (empty disk falls through to it on first boot).
  cdrom {
    file_id   = var.talos_iso_file_id
    interface = "ide3"
  }
  boot_order = ["scsi0", "ide3"]

  network_device {
    bridge = var.proxmox_bridge
  }

  operating_system {
    type = "l26"
  }
}

# Talos worker node.
# Planned static IP (set later in the Talos machine config, not here): 192.168.2.104/24
resource "proxmox_virtual_environment_vm" "talos_wk_01" {
  name      = "talos-wk-01"
  node_name = var.proxmox_node
  vm_id     = 104
  tags      = ["talos", "k8s", "worker"]

  agent {
    enabled = false
  }
  stop_on_destroy = true

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  disk {
    datastore_id = var.talos_datastore
    interface    = "scsi0"
    size         = 40
    file_format  = "raw"
  }

  cdrom {
    file_id   = var.talos_iso_file_id
    interface = "ide3"
  }
  boot_order = ["scsi0", "ide3"]

  network_device {
    bridge = var.proxmox_bridge
  }

  operating_system {
    type = "l26"
  }
}
