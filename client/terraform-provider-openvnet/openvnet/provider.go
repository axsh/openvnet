package openvnet

import (
	"github.com/hashicorp/terraform/helper/schema"
	"github.com/hashicorp/terraform/terraform"
)

func Provider () terraform.ResourceProvider {
	return &schema.Provider{
		ResourcesMap: map[string]*schema.Resource{
			"openvnet_datapath":   OpenVNetDatapath(),
			"openvnet_interface":  OpenVNetInterface(),
			"openvnet_network":    OpenVNetNetwork(),
			"openvnet_route":      OpenVNetRoute(),
			"openvnet_route_link": OpenVNetRouteLink(),
			"openvnet_segment":    OpenVNetSegment(),
		},
	}
}
