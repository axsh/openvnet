provider "openvnet" {
  api_endpoint = "http://localhost:9090/api/1.0"
}

resource "openvnet_network_services" "ns_sample" {
  uuid = "ns-demo"
  mode = "dns"
  # interface_uuid = ""
  # display_name = ""
  # outgoing_port = ""
  # incomding_port = ""
  # type = ""
}
