output "ip_address" {
  value = yandex_compute_instance.vm-1.network_interface[0].nat_ip_address
  description = "Public ip address"
}

output "external_ip" {
  value = yandex_compute_instance.container-web-db-1.network_interface.0.nat_ip_address
}
