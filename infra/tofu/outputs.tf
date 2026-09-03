output "talos_control_plane" {
  description = "Talos control-plane VM"
  value = {
    name  = proxmox_virtual_environment_vm.talos_cp_01.name
    vm_id = proxmox_virtual_environment_vm.talos_cp_01.vm_id
    node  = proxmox_virtual_environment_vm.talos_cp_01.node_name
  }
}

output "talos_worker" {
  description = "Talos worker VM"
  value = {
    name  = proxmox_virtual_environment_vm.talos_wk_01.name
    vm_id = proxmox_virtual_environment_vm.talos_wk_01.vm_id
    node  = proxmox_virtual_environment_vm.talos_wk_01.node_name
  }
}
