provider "openvnet" {
  api_endpoint = "http://localhost:9090/api/1.0"
}

resource "openvnet_topology" "topo" {
  uuuid = "topo-demo"
  mode = "simple_overlay"

  network {
    uuid = "nw-demo"
  }

  route_link {
    uuid = "rl-demo"
  }

  segment {
    uuid = "seg-demo"
  }
}
