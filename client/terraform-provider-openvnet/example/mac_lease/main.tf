provider "openvnet" {
  api_endpoint = "http://localhost:9090/api/1.0"
}

// required resources

resource "openvnet_network" "nw_sample" {
  display_name = "demo"
  ipv4_network = "10.0.0.0"
  ipv4_prefix = "24"
  mode = "virtual"
}

resource "openvnet_interface" "if_sample" {
  display_name = "demo route"
  mode = "vif"
  network_uuid = "${openvnet_network.nw_sample.id}"
  ipv4_address = "10.0.0.100"
  mac_address = "00:00:00:20:20:20"
}

// mac lease

resource "openvnet_mac_lease" "ml_sample" {
   uuid = "ml-demo"
   mac_address = "00:00:00:00:00:01"
   interface_uuid = "${openvnet_interface.if_sample.id}"
   # segment_uuid = ""
}
