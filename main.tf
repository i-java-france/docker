terraform {
  cloud {
    organization = "REPLACE_WITH_YOUR_ORG"

    workspaces {
      name = "REPLACE_WITH_YOUR_WORKSPACE"
    }
  }
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.54.0"
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

data "hcloud_primary_ip" "dokploy-ip" {
  name = "dokploy-ip"
}

resource "hcloud_server" "dokploy" {
  name         = "dokploy"
  server_type  = "cx23"
  image        = "docker-ce"
  location     = "fsn1"
  ssh_keys     = [hcloud_ssh_key.dokploy_ssh_key.id]
  firewall_ids = [] # add your firewall ID's here to apply during provisioning

  public_net {
    ipv4 = data.hcloud_primary_ip.dokploy-ip.id
  }

  # Create directory first
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      private_key = var.ssh_private_key
      host        = self.ipv4_address
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
    }
    source      = "./ssh_init.sh"
    destination = "/opt/dokploy/ssh_init.sh"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      private_key = var.ssh_private_key
      host        = self.ipv4_address
    }

    inline = [
      "sh /opt/dokploy/ssh_init.sh",
      "rm -rf /opt/dokploy",
      "curl -sSL https://dokploy.com/install.sh | sh"
    ]
  }
}
