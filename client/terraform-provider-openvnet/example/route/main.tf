provider "openvnet" {
	 api_endpoint = "http://localhost:9090/api/1.0"
}

// required resources

resource "openvnet_route_link" "rl_sample" {
  mac_address = "00:00:00:00:00:10"
}

resource "openvnet_network" "nw_sample" {
  display_name = "demo"
  ipv4_network = "10.0.0.0"
  ipv4_prefix = "24"
  mode = "virtual"
}

resource "openvnet_interface" "if_sample" {
  display_name = "demo route"
  mode = "simulated"
  network_uuid = "${openvnet_network.nw_sample.id}"
  ipv4_address = "10.0.0.100"
  mac_address = "00:00:00:20:20:20"
}


// route

resource "openvnet_route" "r_sample" {
	 uuid = "r-demo"
	 interface_uuid = "${openvnet_interface.if_sample.id}"
	 route_link_uuid = "${openvnet_route_link.rl_sample.id}"
	 network_uuid = "${openvnet_network.nw_sample.id}"
	 ipv4_network = "10.0.0.0"
	 ipv4_prefix = "24"

	 # ingress = ""
	 # egress = ""
}
