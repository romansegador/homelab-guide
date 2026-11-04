# 1. Download the Ubuntu cloud image onto Proxmox (once; reused by every VM built from it).
resource "proxmox_download_file" "ubuntu" {
  node_name    = var.proxmox_node
  datastore_id = var.files_datastore
  content_type = "import"
  url          = var.ubuntu_image_url
  # Proxmox checks the download against the published checksum before using it.
  checksum           = var.ubuntu_image_sha256
  checksum_algorithm = "sha256"
  # The image is qcow2 inside; the .qcow2 extension tells Proxmox how to import it.
  file_name = replace(basename(var.ubuntu_image_url), ".img", ".qcow2")
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

# 3. The network settings for the first boot (static IP, gateway, DNS).
resource "proxmox_virtual_environment_file" "network_config" {
  node_name    = var.proxmox_node
  datastore_id = var.files_datastore
  content_type = "snippets"

  source_raw {
    file_name = "${var.hostname}-network-config.yaml"
    data = templatefile("${path.module}/cloud-init/network-config.yaml.tftpl", {
      ipv4_cidr     = var.ipv4_cidr
      ipv4_gateway  = var.ipv4_gateway
      dns_servers   = var.dns_servers
      search_domain = var.search_domain
    })
  }
}

# 4. The VM.
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

  # Both cloud-init files are ours. Proxmox's own IP fields aren't used: on Ubuntu 26.04 they
  # make cloud-init rename the network card, which fails (see network-config.yaml.tftpl).
  initialization {
    datastore_id = var.vm_datastore

    user_data_file_id    = proxmox_virtual_environment_file.user_data.id
    network_data_file_id = proxmox_virtual_environment_file.network_config.id
  }
}

output "vm_id" {
  value = proxmox_virtual_environment_vm.machine.vm_id
}

output "ssh" {
  value = "ssh ${var.admin_user}@${split("/", var.ipv4_cidr)[0]}"
}
