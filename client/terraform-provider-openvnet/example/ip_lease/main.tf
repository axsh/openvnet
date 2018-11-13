provider "openvnet" {
   api_endpoint = "http://192.168.21.100:9091/api/1.0"
}

// required resource

resource "openvnet_network" "nw_sample" {
  ipv4_network = "10.0.0.0"
  ipv4_prefix = "24"
  mode = "virtual"
}

// ip lease

resource "openvnet_ip_lease" "il_sample" {
   uuid = "il-demo"
   network_uuid = "${openvnet_network.nw_sample.id}"
   ipv4_address = "10.0.0.221"
   # mac_lease_uuid = ""
   # interface_uuid = ""
   # enable_routing = true
}
