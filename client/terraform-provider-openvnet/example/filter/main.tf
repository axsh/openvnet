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

// filter

resource "openvnet_filter" "fil_sample" {
  uuid = "fil-demo"

  interface_uuid = "${openvnet_interface.if_sample.id}"
  mode = "static"
  ingress_passthrough = true
  egress_passthrough = true

  static {
    protocol = "tcp"
    action = "drop"
    # src_address = "10.0.0.20"
    # dst_address = "10.0.0.10"
    # dst_port = ""
    # src_port = ""
  }

  static {
    protocol = "icmp"
    action = "drop"
    # src_address = "10.0.0.20"
    # dst_address = "10.0.0.10"
    # dst_port = ""
    # src_port = ""
  }
}
