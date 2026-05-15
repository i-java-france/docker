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
  description = "Private SSH key for Coolify provisioning"
  type        = string
  sensitive   = true
}

provider "hcloud" {
  token = var.hcloud_token
}

# Use existing SSH key from Hetzner Cloud
data "hcloud_ssh_key" "coolify" {
  name = "dokploy"  # Reusing existing SSH key
}

# Use the existing primary IP
data "hcloud_primary_ip" "coolify_ip" {
  name = "primary_ip-1"
}

resource "hcloud_server" "coolify" {
  name         = "coolify"
  server_type  = "cx23"
  image        = "ubuntu-24.04"
  location     = "nbg1"
  ssh_keys     = [data.hcloud_ssh_key.coolify.id]
  firewall_ids = []

  public_net {
    ipv4_enabled = true
    ipv4         = data.hcloud_primary_ip.coolify_ip.id
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
      timeout     = "15m"
    }

    inline = [
      # Update system
      "apt-get update",
      
      # Remove Dokploy if it exists
      "if command -v docker &> /dev/null; then",
      "  docker stop $(docker ps -aq) 2>/dev/null || true",
      "  docker rm $(docker ps -aq) 2>/dev/null || true",
      "  docker volume rm $(docker volume ls -q) 2>/dev/null || true",
      "  docker network rm $(docker network ls -q) 2>/dev/null || true",
      "fi",
      
      # Remove Dokploy data directories
      "rm -rf /etc/dokploy 2>/dev/null || true",
      "rm -rf /var/lib/dokploy 2>/dev/null || true",
      
      # SSH hardening
      "sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config",
      "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config",  # Keep as yes for Coolify
      "sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config",
      "systemctl restart ssh.service",
      
      # Install Coolify (works with Ubuntu 24.04 LTS)
      "curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash"
    ]
  }
}

output "server_ip" {
  description = "The public IPv4 address of the Coolify server"
  value       = hcloud_server.coolify.ipv4_address
}

output "coolify_url" {
  description = "URL to access Coolify"
  value       = "http://${hcloud_server.coolify.ipv4_address}:8000"
}