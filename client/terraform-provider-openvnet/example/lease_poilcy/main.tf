provider "openvnet" {
  api_endpoint = "http://localhost:9091/api/1.0"
}

resource "openvnet_lease_poicy" "lp_sample" {
  uuid = "lp-demo"

  mode = ""
  timing = ""
}

resource "openvnet_lease_policy_relation" "lp_sample_relation" {
  uuid = "${openvnet_lease_poicy.lp_sample.id}"

  network {
    uuid = ""
    ip_range_group_uuid = ""
  }

  ip_lease_container {
    uuid = ""
  }

  ip_retention_container {
    uuid = ""
  }

  interface {
    uuid = ""
  }
}
