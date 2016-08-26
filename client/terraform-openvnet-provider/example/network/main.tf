provider "openvnet" {
	 api_host = "http://localhost:9091/api/1.0"
}

resource "openvnet_network" "nw_sample" {
	 uuid = "nw-demo"
	 display_name = "sample network with segments"
	 ipv4_network = "10.0.0.0
	 ipv4_network = "24"
	 network_mode = "virtual"
	 segment_uuid = "seg-demo"
	 editable = true
}