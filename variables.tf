variable "do_token" {
  type        = string
  description = "DigitalOcean authentication token."
}

variable "droplet_name" {
  type        = string
  description = "Name of the DigitalOcean droplet. Must be unique."
}

variable "tags" {
  description = "Tags to set on the droplet."
  type        = list(string)
  default     = []
}

variable "image" {
  description = "Image slug for the desired image. See 'available-images.txt' for a list."
  type        = string
  default     = "ubuntu-20-04-x64"

}

variable "region" {
  description = "Region to assign the droplet to."
  type        = string
  default     = "nyc3"
}

variable "size" {
  description = "Droplet size"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "ssh_key" {
  description = "SSH ID or fingerprint to enable. It must already exist in your DO account."
  type        = string
}

variable "ssh_public_key" {
  description = "Content of the SSH public key"
  type        = string
}

variable "ssh_private_key" {
  description = "Content of the SSH private key"
  type        = string
}

variable "init_script" {
  description = "Initialization script to run"
  default     = "./init.sh"
}

variable "domain" {
  description = "Domain."
  type        = string
  default     = ""
}

variable "records" {
  description = "DNS records to create. The key to the map is the \"name\" attribute. If \"value\"==\"droplet\" it will be assigned to the created droplet's ipv4_address."
  type = map(object({
    domain = string
    type   = string
    value  = string
    ttl    = number
  }))
  default = {}
}

variable "user" {
  type        = string
  description = "Username of user to be added to the droplet."
  default     = "ubuntu"

}

variable "docker_compose_version" {
  description = "Version of docker-compose."
  type        = string
  default     = "v2.2.2"
}

variable "compose_app_dir" {
  description = "Local path to the application directory from which docker-compose will be exectued."
  type        = string
}

variable "droplet_app_dir" {
  description = "Path in the droplet where the docker-compose application will be copied."
  type        = string
  default     = "/home/ubuntu/app"
}
