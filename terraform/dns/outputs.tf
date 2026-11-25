output "dns_records" {
  description = "Managed CloudTask DNS records"

  value = {
    frontend = "${dns_a_record_set.frontend.name}.${var.dns_zone}"
    backend  = "${dns_a_record_set.backend.name}.${var.dns_zone}"
    database = "${dns_a_record_set.database.name}.${var.dns_zone}"
  }
}

output "dns_server" {
  description = "Authoritative DNS server address"
  value       = var.dns_server
}