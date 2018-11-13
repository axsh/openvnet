provider "openvnet" {
  api_endpoint = "http://localhost:9090/api/1.0"
}

resource "openvnet_ip_retention_container" "irc_sample" {
  uuid = "irc-demo"
  # lease_time = 60
  # grace_time = 60
}
