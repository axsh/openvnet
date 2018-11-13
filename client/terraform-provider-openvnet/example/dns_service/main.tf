provider "openvnet" {
  api_endpoint = "http://localhost:9090/api/1.0"
}

// required resources

resource "openvnet_network_services" "ns_sample" {
  uuid = "ns-demo"
  mode = "dns"
}

// dns service

resource "openvnet_dns_service" "dnss_sample" {
  uuid = "dnss-demo"
  network_services_uuid = "${openvnet_network_services.ns_sample.id}"

  dns_record {
    uuid = "dnsr-1"
    name = "rec1"
    ipv4_address = "10.0.0.1"
  }
  dns_record {
    uuid = "dnsr-2"
    name = "rec2"
    ipv4_address = "10.0.0.2"
  }
  dns_record {
    uuid = "dnsr-3"
    name = "rec3"
    ipv4_address = "10.0.0.3"
  }
}
