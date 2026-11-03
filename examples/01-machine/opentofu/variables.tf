# ---- Proxmox connection -------------------------------------------------------------
variable "proxmox_endpoint" {
  description = "Proxmox API URL, e.g. https://proxmox.home.example.com:8006/"
  type        = string
}

variable "proxmox_insecure_tls" {
  description = "Skip TLS verification (true if Proxmox still uses its self-signed certificate)"
  type        = bool
  default     = true
}

variable "proxmox_ssh_user" {
  description = "Restricted SSH user on the Proxmox host, used only to upload the cloud-init snippet"
  type        = string
  default     = "tofu"
}

variable "proxmox_node" {
  description = "Proxmox node name (see `pvesh get /nodes`)"
  type        = string
}

variable "vm_datastore" {
  description = "Storage for the VM disks"
  type        = string
  default     = "local-lvm"
}

variable "files_datastore" {
  description = "Directory storage with the 'import' and 'snippets' content types enabled"
  type        = string
  default     = "local"
}

variable "network_bridge" {
  description = "Bridge the VM's network card connects to"
  type        = string
  default     = "vmbr0"
}

# ---- The machine ---------------------------------------------------------------------
variable "vm_id" {
  description = "Proxmox VM id (null lets Proxmox pick the next free one)"
  type        = number
  default     = null
}

variable "hostname" {
  description = "VM name and OS hostname, e.g. lab-1"
  type        = string
}

variable "cpu_cores" {
  type    = number
  default = 6
}

variable "memory_mb" {
  type    = number
  default = 16384
}

variable "os_disk_gb" {
  type    = number
  default = 40
}

variable "data_disk_gb" {
  type    = number
  default = 100
}

variable "ubuntu_image_url" {
  description = "Ubuntu cloud image to boot from"
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

# ---- Network and access ---------------------------------------------------------------
variable "ipv4_cidr" {
  description = "Static address with prefix, e.g. 192.168.10.50/24"
  type        = string
}

variable "ipv4_gateway" {
  description = "e.g. 192.168.10.1"
  type        = string
}

variable "dns_servers" {
  description = "e.g. [\"192.168.10.53\"]"
  type        = list(string)
}

variable "search_domain" {
  description = "e.g. home.example.com"
  type        = string
}

variable "admin_user" {
  description = "The login user created on the VM (SSH key only, passwordless sudo)"
  type        = string
  default     = "admin"
}

variable "ssh_public_key_file" {
  description = "Path to the SSH public key allowed to log in, e.g. ~/.ssh/id_ed25519.pub"
  type        = string
}

variable "timezone" {
  type    = string
  default = "Etc/UTC"
}

# ---- State encryption -----------------------------------------------------------------
variable "state_passphrase" {
  description = "Encrypts the OpenTofu state. Export TF_VAR_state_passphrase; never put it in a file"
  type        = string
  sensitive   = true
}
