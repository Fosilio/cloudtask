variable "dns_server" {
  description = "IP address of the authoritative DNS server"
  type        = string
}

variable "dns_zone" {
  description = "Authoritative DNS zone"
  type        = string
  default     = "cloudtask.test."
}

variable "tsig_key_name" {
  description = "TSIG authentication key name"
  type        = string
  default     = "cloudtask-update"
}

variable "tsig_secret" {
  description = "TSIG authentication secret"
  type        = string
  sensitive   = true
}

variable "dns_ttl" {
  description = "DNS record TTL in seconds"
  type        = number
  default     = 300
}

variable "backend_ip" {
  description = "Backend address on the app network"
  type        = string
  default     = "172.20.20.20"
}

variable "database_ip" {
  description = "Database address on the db network"
  type        = string
  default     = "172.20.30.30"
}