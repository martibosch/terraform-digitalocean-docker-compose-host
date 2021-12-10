variable "local_path" { type = string }
variable "remote_path" { type = string }

variable "host" { type = string }
variable "user" { type = string }
variable "private_key" { type = string }

resource "null_resource" "provisioner_container" {
  triggers = {
    host = var.host
    md5  = data.external.md5path.result.md5
  }
  connection {
    host        = var.host
    user        = var.user
    private_key = var.private_key
  }
  provisioner "file" {
    source      = var.local_path
    destination = var.remote_path
  }
}

data "external" "md5path" {
  program = ["bash", "${path.module}/md5path.sh"]
  query   = { path = "${var.local_path}" }
}
