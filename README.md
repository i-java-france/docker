About this Repo
======

This is the Git repo of the official Docker image for [Odoo](https://registry.hub.docker.com/_/odoo/). See the Hub page for the full readme on how to use the Docker image and for information regarding contributing and issues.

The full readme is generated over in [docker-library/docs](https://github.com/docker-library/docs), specifically in [docker-library/docs/odoo](https://github.com/docker-library/docs/tree/master/odoo).


# Dokploy Terraform Deployment

With this project you can provision a Hetzner VPS with [Dokploy](https://dokploy.com/) pre-installed using Terraform.

**What is Dokploy?**

An open-source, self-hosted Platform-as-a-Service (PaaS) that simplifies application deployment, database management, and server configuration through a web UI and CLI.

**Why this project?**

By combining Terraform with Dokploy, you get:

- **Infrastructure as Code**: Reproducible server provisioning which you can include in your version control
- **Easy Deployment**: Use Dokploy's UI/CLI to manage your applications after initial setup

Additionally:

- **Server hardening and added security**: SSH is hardened and root login is disabled by default. Only clients with the configured SSH key can access the server. To skip this step, remove the remote-exec line that runs `ssh_init.sh` in `main.tf`.

## CI/CD with GitHub Actions

This project includes automated workflows for infrastructure and application testing.

### Terraform CI/CD

The `.github/workflows/terraform.yml` workflow automates the following:
- **Pull Requests**: Runs `terraform fmt`, `terraform validate`, and `terraform plan`. The plan output is posted as a comment on the PR.
- **Main Branch Push**: Runs `terraform apply` to automatically deploy changes to Hetzner Cloud.

#### Setup Requirements

1. **Terraform Cloud**:
   - Create an account at [app.terraform.io](https://app.terraform.io/).
   - Create an organization and a workspace.
   - Update `main.tf` with your organization and workspace names:
     ```hcl
     cloud {
       organization = "YOUR_ORG"
       workspaces {
         name = "YOUR_WORKSPACE"
       }
     }
     ```
2. **GitHub Secrets**:
   - `TF_API_TOKEN`: Your Terraform Cloud API token.
   - `HCLOUD_TOKEN`: Your Hetzner Cloud API token.
   - `SSH_PUBLIC_KEY`: The public SSH key for the server.
   - `SSH_PRIVATE_KEY`: The private SSH key (used by Terraform for provisioning).

### Odoo Image Testing

The `.github/workflows/odoo-test.yml` workflow automatically builds the Docker images for Odoo 17.0, 18.0, and 19.0 on every push or PR that modifies their respective directories. This ensures that your custom changes don't break the build.

## Table of Contents

- [Default VPS Configuration](#default-vps-configuration)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Accessing the Server](#accessing-the-server)
- [Cleaning Up](#cleaning-up)

## Default VPS Configuration

The VPS will be provisioned with the following settings (configurable in `main.tf`):

```tf
server_type  = "cx23"
image        = "docker-ce"
location     = "fsn1"
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) installed
- [Hetzner Cloud](https://www.hetzner.com/) account with:
  - Activated account
  - IPv4 primary IP named "dokploy-ip"
  - [API token](https://docs.hetzner.com/cloud/api/getting-started/generating-api-token/)
  - **Optional:** Firewall rules (add to `main.tf` under `firewall_ids`)

## Setup Instructions

### 1. Create SSH Key

Generate SSH keys for server provisioning and access:

```bash
mkdir -p ~/.ssh/dokploy
ssh-keygen -t ed25519 -C "dokploy" -f ~/.ssh/dokploy/id_ed25519
```

The SSH keys will be stored in `~/.ssh/dokploy/` on your local machine.

### 2. Configure Hetzner API Token

Once you've acquired your [Hetzner API token](https://docs.hetzner.com/cloud/api/getting-started/generating-api-token/), store it in the root directory of this project:

```bash
echo "your-api-token-here" > hetzner-token.txt
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Provision the Server

```bash
terraform fmt
terraform validate
terraform apply
```

This will:

- Create a new server on Hetzner Cloud
- Disable root user and apply SSH hardening
- Install Dokploy

Upon successful completion, you'll see:

```bash
hcloud_server.dokploy-manager (remote-exec): Congratulations, Dokploy is installed!
hcloud_server.dokploy-manager (remote-exec): Please go to http://<your-ip>:3000
```

> **Note:** Your server's firewall should expose port 3000 otherwise Dokploy will not be accessible.

## Cleaning Up

To destroy all resources created by Terraform:

```bash
terraform destroy
```

**Warning:** This will permanently delete your server and all data on it.

> **Note:** If there's a problem with cleaning up the resource automatically, make sure to clean up the known hosts on your local machine and SSH key for this project under `Hetzner Console > Security > SSH keys`.
