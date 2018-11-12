provider "openvnet" {
	 api_endpoint = "http://localhost:9090/api/1.0"
}

// required resources

resource "openvnet_segment" "seg_sample" {
  mode = "virtual"
}

resource "openvnet_network" "nw_sample" {
  display_name = "sample network with segments"
  ipv4_network = "10.0.0.0"
  ipv4_prefix = "24"
  mode = "physical"
}

resource "openvnet_route_link" "rl_sample" {
  mac_address = "00:00:00:02:02:10"
}

resource "openvnet_interface" "if_sample" {
  display_name = "interface with all possible parameters"
  mode = "host"
  owner_datapath_uuid = "${openvnet_datapath.dp_sample.id}"
  network_uuid = "${openvnet_network.nw_sample.id}"
  ipv4_address = "10.0.0.100"
  mac_address = "00:00:00:02:02:20"
}

// datapath

resource "openvnet_datapath" "dp_sample" {
	 display_name = "datapath with all possible parameters"
	 # uuid = "dp-demo"
	 dpid = "0x0000aaaaaaaaaaaa"
	 node_id = "vna"
}

// setting relations

resource "openvnet_datapath_relation" "dp_sample_relation" {
	uuid = "${openvnet_datapath.dp_sample.id}"

	network {
    uuid = "${openvnet_network.nw_sample.id}"
    mac_address = "00:00:00:02:02:02"
		interface_uuid = "${openvnet_interface.if_sample.id}"
	}

	route_link {
    uuid = "${openvnet_route_link.rl_sample.id}"
    mac_address = "00:00:00:02:02:03"
    interface_uuid = "${openvnet_interface.if_sample.id}"
  }

	segment {
    uuid = "${openvnet_segment.seg_sample.id}"
    mac_address = "00:00:00:02:02:04"
    interface_uuid = "${openvnet_interface.if_sample.id}"
  }
}
