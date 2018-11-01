provider "openvnet" {
   api_endpoint = "http://192.168.21.100:9090/api/1.0"
}

resource "openvnet_ip_lease" "il_sample" {
   uuid = "il-demo"
   network_uuid = "nw-test"
   ipv4_address = "10.0.1.221"
   mac_lease_uuid = ""
   interface_uuid = ""
   enable_routing = true
}
