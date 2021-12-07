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

resource "digitalocean_droplet" "droplet" {
  image    = var.image
  name     = var.droplet_name
  region   = var.region
  tags     = var.tags
  size     = var.size
  ssh_keys = var.ssh_keys

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      host        = self.ipv4_address
      private_key = var.ssh_private_key
    }
    inline = [
      "useradd -m -s /bin/bash -G sudo -p $(head /dev/urandom | tr -dc a-zA-Z0-9 | head -c 10 | openssl passwd -crypt -stdin) ${var.user}",
      "mkdir -p /home/${var.user}/.ssh",
      "cp /root/.ssh/authorized_keys /home/${var.user}/.ssh/authorized_keys",
      "chown -R ${var.user}:${var.user} /home/${var.user}/.ssh",
      "chmod 700 /home/${var.user}/.ssh",
      "chmod 600 /home/${var.user}/.ssh/authorized_keys",
      "sed -i 's/.*PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config",
      "sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config",
      "sed -i 's/.*PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config",
      "systemctl restart sshd",
      "echo '${var.user} ALL=(ALL) NOPASSWD:ALL' | EDITOR='tee -a' visudo",
    ]
  }

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
    source      = "${var.compose_app_dir}/"
    destination = var.droplet_app_dir
  }

  # copy init script
  provisioner "file" {
    source      = var.init_script
    destination = "~/init.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io",
      "sudo service docker start",
      "sudo usermod -aG docker ${var.user}",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/${var.docker_compose_version}/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ./init.sh",
      "./init.sh",
    ]
  }

}

resource "digitalocean_domain" "default" {
  count      = var.domain != "" ? 1 : 0
  name       = var.domain
  ip_address = digitalocean_droplet.droplet.ipv4_address
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
