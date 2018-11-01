provider "openvnet" {
  api_endpoint = "http://localhost:9090/api/1.0"
}

resource "openvnet_mac_range_group" "mrg_sample" {
  uuid = "mgr-dpg"

  mac_range {
    begin_mac_address = "00:00:00:00:00:00"
    end_mac_address = "00:00:00:00:00:ff"
  }
}
