output "ip" {
  description = "Public IPv4 address of the droplet."
  value       = digitalocean_droplet.droplet.ipv4_address
}

