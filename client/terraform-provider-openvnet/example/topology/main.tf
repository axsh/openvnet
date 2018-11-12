provider "openvnet" {
  api_endpoint = "http://localhost:9090/api/1.0"
}

// required resources

resource "openvnet_segment" "seg_test" {
  mode = "virtual"
}

resource "openvnet_network" "nw_sample" {
  display_name = "sample network with segments"
  ipv4_network = "10.0.0.0"
  ipv4_prefix = "24"
  mode = "physical"
}

resource "openvnet_network" "nw_sample2" {
  display_name = "sample network with segments"
  ipv4_network = "20.0.0.0"
  ipv4_prefix = "24"
  mode = "virtual"
}

resource "openvnet_route_link" "rl_sample" {
  mac_address = "00:00:00:00:00:00"
}

resource "openvnet_datapath" "dp_sample" {
  display_name = "datapath with all possible parameters"
  dpid = "0x0000aaaaaaaaaaaa"
  node_id = "vna"
}

resource "openvnet_interface" "if_sample" {
  display_name = "interface with all possible parameters"
  mode = "host"
  owner_datapath_uuid = "${openvnet_datapath.dp_sample.id}"
  network_uuid = "${openvnet_network.nw_sample.id}"
  ipv4_address = "10.0.0.100"
  mac_address = "00:00:00:20:20:20"
}

// topoplogy

resource "openvnet_topology" "topo-under" {
  uuid = "topo-demo10"
  mode = "simple_underlay"
}

resource "openvnet_topology" "topo-over" {
  uuid = "topo-demo20"
  mode = "simple_overlay"

  datapath {
    uuid = "${openvnet_datapath.dp_sample.id}"
    interface_uuid = "${openvnet_interface.if_sample.id}"
  }

  network {
    uuid = "${openvnet_network.nw_sample2.id}"
  }

  route_link {
    uuid = "${openvnet_route_link.rl_sample.id}"
  }

  underlay {
    uuid = "${openvnet_topology.topo-under.id}"
  }

  segment {
    uuid = "${openvnet_segment.seg_test.id}"
  }

}
