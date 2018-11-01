provider "openvnet" {
  api_endpoint = "http://localhost:9090/api/1.0"
}

resource "openvnet_ip_lease_container" "ilc_sample" {
  uuid = "ilc-demo"
}
