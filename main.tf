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

variable "ssh_private_key" {
  description = "Private SSH key for Dokploy provisioning"
  type        = string
  sensitive   = true
}

provider "hcloud" {
  token = var.hcloud_token
}

# Use existing SSH key from Hetzner Cloud
data "hcloud_ssh_key" "dokploy" {
  name = "dokploy"
}

# Use the existing primary IP
data "hcloud_primary_ip" "dokploy_ip" {
  name = "primary_ip-1"
}

resource "hcloud_server" "dokploy" {
  name         = "dokploy"
  server_type  = "cx23"  # Changed from cx22 to cpx11 (cheapest ARM server)
  image        = "ubuntu-24.04"
  location     = "nbg1"
  ssh_keys     = [data.hcloud_ssh_key.dokploy.id]
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
      # SSH hardening
      "sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config",
      "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config",
      "sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config",
      "systemctl restart ssh.service",
      # Install Dokploy
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