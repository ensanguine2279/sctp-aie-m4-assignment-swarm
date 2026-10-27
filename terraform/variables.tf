variable "project_id" {
  description = "GCP project ID that will hold the swarm."
  type        = string
}

variable "region" {
  description = "Region for the static IP and subnet."
  type        = string
  default     = "asia-southeast1"
}

variable "zone" {
  description = "Zone for the VMs."
  type        = string
  default     = "asia-southeast1-b"
}

variable "network" {
  description = "VPC network to use."
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "Subnetwork in var.region. The 'default' network has a subnetwork called 'default' in every region."
  type        = string
  default     = "default"
}

variable "machine_type" {
  description = "VM size. e2-medium is 2 vCPU and 4 GB."
  type        = string
  default     = "e2-medium"
}

variable "boot_disk_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 30
}

variable "node_count" {
  description = "Number of swarm nodes. Keep it odd (3) so Raft keeps quorum when one node fails."
  type        = number
  default     = 3

  validation {
    condition     = var.node_count >= 1 && var.node_count % 2 == 1
    error_message = "node_count must be an odd number (1, 3, 5...)."
  }
}

variable "ssh_source_ranges" {
  description = "CIDR ranges allowed to reach SSH (port 22). Narrow this to your own IP when you can; GitHub Actions runners use changing addresses."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "web_source_ranges" {
  description = "CIDR ranges allowed to reach Caddy on ports 80 and 443. Port 80 must be reachable by Let's Encrypt."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
