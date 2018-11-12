provider "openvnet" {
  api_endpoint = "http://localhost:9090/api/1.0"
}

// required resources

resource "openvnet_network" "nw_sample" {
  display_name = "sample network with segments"
  ipv4_network = "10.0.0.0"
  ipv4_prefix = "24"
  mode = "virtual"
}

resource "openvnet_ip_range_group" "iprg_sample" {
  ip_range {
    begin_ipv4_address = "10.0.0.1"
    end_ipv4_address = "10.0.0.100"
  }
}

resource "openvnet_ip_retention_container" "icr_sample" {}

resource "openvnet_ip_lease_container" "ilc_sample" {}

resource "openvnet_interface" "if_sample" {
  mode = "vif"
  mac_address = "00:00:00:10:10:10"
  network_uuid = "${openvnet_network.nw_sample.id}"
}

// lease policy

resource "openvnet_lease_policy" "lp_sample_relation" {
  uuid = "lp-sample"
  timing = ""

  network {
    uuid = "${openvnet_network.nw_sample.id}"
    ip_range_group_uuid = "${openvnet_ip_range_group.iprg_sample.id}"
  }

  ip_retention_container {
    uuid = "${openvnet_ip_retention_container.icr_sample.id}"
  }

  ip_lease_container {
    uuid = "${openvnet_ip_lease_container.ilc_sample.id}"
  }

  interface {
    uuid = "${openvnet_interface.if_sample.id}"
  }
}
