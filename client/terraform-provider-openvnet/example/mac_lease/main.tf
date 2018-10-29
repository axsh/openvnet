provider "openvnet" {
  api_endpoint = "http://localhost:9091/api/1.0"
}

resource "openvnet_mac_lease" "lease" {
   uuid = "ml-demo"
   mac_address = "00:00:00:00:00:01"
   segment_uuid = "seg-demo"
}
