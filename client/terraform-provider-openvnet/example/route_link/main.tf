provider "openvnet" {
	 api_endpoint = "http://localhost:9091/api/1.0"
}

resource "openvnet_route_link" "rl_sample" {
	 uuid = "rl-demo"
	 mac_address = "00:00:00:00:00:00"
}