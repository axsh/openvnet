package openvnet

import (
	"github.com/hashicorp/terraform/helper/schema"
	"github.com/hashicorp/terraform/terraform"
)

func Provider () terraform.ResourceProvider {
	return &schema.Provider{
		ResourcesMap: map[string]*schema.Resource{
			"openvnet_datapath":   resourceOpenVNetDatapaht(),
			"openvnet_interface":  resourceOpenVNetInterface(),
			"openvnet_network":    resourceOpenVNetNetwork(),
			"openvnet_route":      resourceOpenVNetRoute(),
			"openvnet_route_link": resourceOpenVNetRouteLink(),
			"openvnet_segment":    resourceOpenVNetSegment(),
		},
	}
}
