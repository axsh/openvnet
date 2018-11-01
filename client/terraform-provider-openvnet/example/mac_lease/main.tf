provider "openvnet" {
  api_endpoint = "http://192.168.21.100:9090/api/1.0"
}

resource "openvnet_mac_lease" "ml_sample" {
   uuid = "ml-demo"
   mac_address = "00:00:00:00:00:01"
   interface_uuid = "if-demo"
   segment_uuid = ""
}
