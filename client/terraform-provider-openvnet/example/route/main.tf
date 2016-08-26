provider "openvnet" {
	 api_host = "http://localhost:9091/api/1.0"
}

resource "openvnet_route" "r_sample" {
	 uuid = "r-demo"
	 interface_uuid = "if-demo"
	 route_link_uuid = "rl-demo"
	 network_uuid = "nw-demo"
	 ipv4_network = "10.0.0.0"
	 ipv4_prefix = "24"

	 ingress = ""
	 egress = ""
}