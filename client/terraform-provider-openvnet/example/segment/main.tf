provider "openvnet" {
	 api_endpoint = "http://localhost:9091/api/1.0"
}

resource "openvnet_segment" "seg_sample" {
	 uuid = "seg-demo"
	 mode = "virtual"
}