terraform {
  cloud {
    organization = "i-java-france"

    workspaces {
      name = "docker"
    }
  }
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.54.0"
    }
  }
}

variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Public SSH key for Dokploy"
  type        = string
}

variable "ssh_private_key" {
  description = "Private SSH key for Dokploy provisioning"
  type        = string
  sensitive   = true
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "dokploy_ssh_key" {
  name       = "dokploy_ssh_key"
  public_key = var.ssh_public_key
}

# Use the existing primary IP
data "hcloud_primary_ip" "dokploy_ip" {
  name = "primary_ip-1"  # Changed to match your actual IP name
}

resource "hcloud_server" "dokploy" {
  name         = "dokploy"
  server_type  = "cx22"  # Changed from cx23 (doesn't exist) to cx22
  image        = "docker-ce"
  location     = "fsn1"
  ssh_keys     = [hcloud_ssh_key.dokploy_ssh_key.id]
  firewall_ids = []

  public_net {
    ipv4_enabled = true
    ipv4         = data.hcloud_primary_ip.dokploy_ip.id
    ipv6_enabled = true
  }

  # Wait for server to be ready
  provisioner "local-exec" {
    command = "sleep 30"
  }

  # Create directory first
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      private_key = var.ssh_private_key
      host        = self.ipv4_address
      timeout     = "5m"
    }
    inline = [
      "mkdir -p /opt/dokploy"
    ]
  }

  # Copy scripts
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "root"
      private_key = var.ssh_private_key
      host        = self.ipv4_address
      timeout     = "5m"
    }
    source      = "${path.module}/ssh_init.sh"
    destination = "/opt/dokploy/ssh_init.sh"
  }

  # Execute installation
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      private_key = var.ssh_private_key
      host        = self.ipv4_address
      timeout     = "10m"
    }

    inline = [
      "chmod +x /opt/dokploy/ssh_init.sh",
      "sh /opt/dokploy/ssh_init.sh",
      "rm -rf /opt/dokploy",
      "curl -sSL https://dokploy.com/install.sh | sh"
    ]
  }
}

output "server_ip" {
  description = "The public IPv4 address of the Dokploy server"
  value       = hcloud_server.dokploy.ipv4_address
}

output "dokploy_url" {
  description = "URL to access Dokploy"
  value       = "http://${hcloud_server.dokploy.ipv4_address}:3000"
}