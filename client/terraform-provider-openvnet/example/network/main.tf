provider "openvnet" {
	 api_endpoint = "http://localhost:9091/api/1.0"
}

resource "openvnet_network" "nw_sample" {
	 uuid = "nw-demo"
	 display_name = "sample network with segments"
	 ipv4_network = "10.0.0.0"
	 ipv4_prefix = "24"
	 network_mode = "virtual"
	 segment_uuid = ""
	 editable = true
}
