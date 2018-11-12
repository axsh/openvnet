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

resource "openvnet_route_link" "rl_sample" {
  mac_address = "00:00:00:00:00:10"
}

// filter

resource "openvnet_translation" "tr_sample" {
  uuid = "tr-demo"

  interface_uuid = "${openvnet_interface.if_sample.id}"
  mode = "static_address"
  passthrough = true

  static_address {
    route_link_uuid = "${openvnet_route_link.rl_sample.id}"
    ingress_ipv4_address = "10.0.0.10"
    egress_ipv4_address = "10.0.1.10"
    # ingress_port_number = ""
		# egress_port_number = ""
    # ingress_network_uuid = ""
    # egress_network_uuid = ""
  }

  static_address {
    route_link_uuid = "${openvnet_route_link.rl_sample.id}"
    ingress_ipv4_address = "10.0.0.11"
    egress_ipv4_address = "10.0.1.11"
    # ingress_port_number = ""
    # egress_port_number = ""
    # ingress_network_uuid = ""
    # egress_network_uuid = ""
  }
}
