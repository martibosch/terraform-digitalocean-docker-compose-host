output "id" {
  description = "ID of the created droplet."
  value       = digitalocean_droplet.droplet.id
}

output "name" {
  description = "Name of the created droplet."
  value       = digitalocean_droplet.droplet.name
}

output "ipv4_address" {
  description = "Public IPv4 address of the droplet."
  value       = digitalocean_droplet.droplet.ipv4_address
}

