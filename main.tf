provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "droplet" {
  image    = var.image
  name     = var.droplet_name
  region   = var.region
  tags     = var.tags
  size     = var.size
  ssh_keys = coalescelist(concat(file(var.ssh_key_file), var.ssh_keys))

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

    connection {
      type = "ssh"
      user = "root"
      host = self.ipv4_address
    }
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "root"
      host = self.ipv4_address
    }
    inline = [
      "chmod +x ./init.sh",
      "./init.sh",
    ]
  }

}

