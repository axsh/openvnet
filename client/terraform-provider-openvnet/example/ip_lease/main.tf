provider "openvnet" {
  api_endpoint = "http://localhost:9091/api/1.0"
}

resource "openvnet_ip_lease" "lease" {
   uuid = "il-demo"
   network_uuid = "nw-test"
   ipv4_address = "10.0.0.1"
   mac_lease_uuid = "ml-demo"
   interface_uuid = "if-demo"
   enable_routing = true
}
