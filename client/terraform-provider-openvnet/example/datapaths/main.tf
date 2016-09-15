provider "openvnet" {
	 api_host = "http://localhost:9091/api/1.0"
}

resource "openvnet_datapath" "dp_sample" {
	 display_name = "datapath with all possible parameters"
	 uuid = "dp-demo"
	 dpid = "0x0000aaaaaaaaaaaa"
	 node_id = "vna"
}

resource "openvnet_datapath_relation" "dp_sample_relation" {
	uuid = "${openvnet_datapath.dp_sample.id}"

	network {
		 mac_address = ""
		interface_uuid = ""
	}

	route_link {
		mac_address = ""
		interface_uuid = ""
	}

	segment {
		mac_address = ""
		interface_uuid = ""
	}
}