provider "openvnet" {
  api_endpoint = "http://localhost:9090/api/1.0"
}

resource "openvnet_topology" "topo-under" {
  uuid = "topo-demo1"
  mode = "simple_underlay"
}

resource "openvnet_topology" "topo-over" {
  uuuid = "topo-demo2"
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

  underlay {
    uuid = "topo-demo1"
  }
}
