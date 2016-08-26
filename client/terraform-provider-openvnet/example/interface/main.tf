provider "openvnet" {
	 api_host = "http://localhost:9091/api/1.0"
}

resource "openvnet_interface" "if_sample" {
	 display_name = "interface with all possible parameters"
	 uuid = "if-demo"
	 mode = "virtual"
	 ipv4_address = "10.0.0.1"
	 mac_address = "00:00:00:00:00:01"
	 network_uuid = "nw-demo"
	 segment_uuid = "seg-demo"
	 port_name = "if"

	 ingress_filtering_enable = false
	 enable_route_translations = false
	 enable_filtering = false
	 enable_routing = false

	 port {
	       datapath_uuid = ""
	       port_name = ""
	       singular =
	 }

	 security_group {
	 	security_group_id = ""
	 }
}