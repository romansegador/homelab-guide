# 1. Download the Ubuntu cloud image onto Proxmox (once; reused by every VM built from it).
resource "proxmox_download_file" "ubuntu" {
  node_name    = var.proxmox_node
  datastore_id = var.files_datastore
  content_type = "import"
  url          = var.ubuntu_image_url
  # The image is qcow2 inside; the extension tells Proxmox how to import it.
  file_name = "noble-server-cloudimg-amd64.qcow2"
}

# 2. The cloud-init user-data: what the VM does on its first boot.
resource "proxmox_virtual_environment_file" "user_data" {
  node_name    = var.proxmox_node
  datastore_id = var.files_datastore
  content_type = "snippets"

  source_raw {
    file_name = "${var.hostname}-user-data.yaml"
    data = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", {
      hostname       = var.hostname
      admin_user     = var.admin_user
      ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_file)))
      timezone       = var.timezone
    })
  }
}

# 3. The VM.
resource "proxmox_virtual_environment_vm" "machine" {
  name      = var.hostname
  node_name = var.proxmox_node
  vm_id     = var.vm_id
  tags      = ["homelab", "opentofu"]

  on_boot         = true # start with the host
  stop_on_destroy = true
  machine         = "q35"
  scsi_hardware   = "virtio-scsi-single"

  agent {
    enabled = true # qemu-guest-agent is installed by cloud-init
  }

  operating_system {
    type = "l26" # Linux
  }

  cpu {
    cores = var.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.memory_mb
  }

  # OS disk, created from the cloud image and grown to os_disk_gb. Appears as /dev/sda.
  disk {
    interface    = "scsi0"
    datastore_id = var.vm_datastore
    import_from  = proxmox_download_file.ubuntu.id
    size         = var.os_disk_gb
    iothread     = true
    discard      = "on"
    ssd          = true
  }

  # Data disk, empty. Appears as /dev/sdb; cloud-init formats it and mounts it at /data.
  disk {
    interface    = "scsi1"
    datastore_id = var.vm_datastore
    file_format  = "raw"
    size         = var.data_disk_gb
    iothread     = true
    discard      = "on"
    ssd          = true
  }

  network_device {
    bridge = var.network_bridge
  }

  # Cloud images expect a serial console.
  serial_device {}

  initialization {
    datastore_id = var.vm_datastore

    ip_config {
      ipv4 {
        address = var.ipv4_cidr
        gateway = var.ipv4_gateway
      }
    }

    dns {
      servers = var.dns_servers
      domain  = var.search_domain
    }

    user_data_file_id = proxmox_virtual_environment_file.user_data.id
  }
}

output "vm_id" {
  value = proxmox_virtual_environment_vm.machine.vm_id
}

output "ssh" {
  value = "ssh ${var.admin_user}@${split("/", var.ipv4_cidr)[0]}"
}
