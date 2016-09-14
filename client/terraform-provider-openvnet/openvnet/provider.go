package openvnet

import (
	"github.com/hashicorp/terraform/helper/schema"
	"github.com/hashicorp/terraform/terraform"
)

func Provider () terraform.ResourceProvider {
	return &schema.Provider{

		Schema: map[string]*schema.Schema{
			"api_endpoint": &schema.Schema{
				Type:        schema.TypeString,
				Required:    true,
				DefaultFunc: schema.EnvDefaultFunc("OPENVNET_API_ENDPOINT", nil),
				Description: "Endpoint URL for API.",
			},
		},

		ResourcesMap: map[string]*schema.Resource{
			"openvnet_datapath":   OpenVNetDatapath(),
			"openvnet_interface":  OpenVNetInterface(),
			"openvnet_network":    OpenVNetNetwork(),
			"openvnet_route":      OpenVNetRoute(),
			"openvnet_route_link": OpenVNetRouteLink(),
			"openvnet_segment":    OpenVNetSegment(),
			"openvnet_mac_range_group": OpenVNetMacRangeGroup(),
		},

		ConfigureFunc: providerConfigure,
	}
}

func providerConfigure(d *schema.ResourceData) (interface{}, error) {
	config := Config{
		APIEndpoint: d.Get("api_endpoint").(string),
	}

	return config.Client()
}