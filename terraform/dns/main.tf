resource "dns_a_record_set" "frontend" {
  zone      = var.dns_zone
  name      = "frontend"
  addresses = [var.dns_server]
  ttl       = var.dns_ttl
}

resource "dns_a_record_set" "backend" {
  zone      = var.dns_zone
  name      = "backend"
  addresses = [var.backend_ip]
  ttl       = var.dns_ttl
}

resource "dns_a_record_set" "database" {
  zone      = var.dns_zone
  name      = "db"
  addresses = [var.database_ip]
  ttl       = var.dns_ttl
}