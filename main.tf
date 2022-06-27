terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

data "template_file" "cloud-init-yaml" {
  template = file("${path.module}/files/cloud-init.yml")
  vars = {
    user                   = var.user
    init_ssh_public_key    = var.ssh_public_key
    docker_compose_version = var.docker_compose_version
  }
}

resource "digitalocean_droplet" "droplet" {
  image    = var.image
  name     = var.droplet_name
  region   = var.region
  tags     = var.tags
  size     = var.size
  ssh_keys = [var.ssh_key]

  user_data = data.template_file.cloud-init-yaml.rendered

  connection {
    type        = "ssh"
    user        = var.user
    host        = self.ipv4_address
    private_key = var.ssh_private_key
  }

  # copy app directory
  provisioner "remote-exec" {
    inline = ["mkdir -p ${var.droplet_app_dir}"]
  }

  provisioner "file" {
    source      = var.compose_app_dir
    destination = var.droplet_app_dir
  }

  # copy init script
  provisioner "file" {
    source      = var.init_script
    destination = "/home/${var.user}/init.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ./init.sh",
      "./init.sh",
    ]
  }

}

resource "digitalocean_domain" "default" {
  count = var.domain != "" ? 1 : 0
  name  = var.domain
}

resource "digitalocean_record" "default" {
  for_each = length(var.records) > 0 ? var.records : {}

  depends_on = [digitalocean_domain.default]
  domain     = each.value.domain
  name       = each.key
  type       = each.value.type
  value      = each.value.type == "A" && each.value.value == "droplet" ? digitalocean_droplet.droplet.ipv4_address : each.value.value
  ttl        = each.value.ttl >= 0 ? each.value.ttl : 3600
}
