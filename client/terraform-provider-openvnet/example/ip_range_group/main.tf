provider "openvnet" {
  api_endpoint = "http://localhost:9090/api/1.0"
}

resource "openvnet_ip_range_group" "iprg" {
  uuid = "ipgr-demo"

  ip_range {
    begin_ipv4_address = "10.0.0.1"
    end_ipv4_address = "10.0.0.100"
  }
}
