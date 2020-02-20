provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_ssh_key" "main_key" {
  count = var.ssh_key_file != "" ? 1 : 0

  name       = regex("\\b{1}([\\w\\d-_.]+@.+)", file(var.ssh_key_file))[0]
  public_key = file(var.ssh_key_file)
}

resource "digitalocean_droplet" "droplet" {
  image    = var.image
  name     = var.droplet_name
  region   = var.region
  tags     = var.tags
  size     = var.size
  ssh_keys = coalescelist([digitalocean_ssh_key.main_key[0].fingerprint], var.ssh_keys)

  depends_on = [
    digitalocean_droplet.droplet,
  ]

  connection {
    type = "ssh"
    user = "root"
    host = self.ipv4_address
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
      "sudo add-apt-repository \"deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io",
      "sudo service docker start",
      "sudo usermod -aG docker $USER",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
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
  for_each = var.domain != "" && length(var.records) > 0 ? var.records : {}

  domain = digitalocean_domain.default[0].name
  name   = each.key
  type   = each.value.type
  value  = each.value.value
  ttl    = each.value.ttl >= 0 ? each.value.ttl : 3600
}
