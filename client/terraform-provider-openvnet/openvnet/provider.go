package openvnet

import (
	"github.com/hashicorp/terraform/helper/schema"
	"github.com/hashicorp/terraform/terraform"
)

func Provider() terraform.ResourceProvider {
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
			"openvnet_datapath":               OpenVNetDatapath(),
			"openvnet_datapath_relation":      OpenVNetDatapathRelation(),
			"openvnet_interface":              OpenVNetInterface(),
			"openvnet_network":                OpenVNetNetwork(),
			"openvnet_route":                  OpenVNetRoute(),
			"openvnet_route_link":             OpenVNetRouteLink(),
			"openvnet_segment":                OpenVNetSegment(),
			"openvnet_mac_range_group":        OpenVNetMacRangeGroup(),
			"openvnet_topology":               OpenVNetTopology(),
			"openvnet_mac_lease":              OpenVNetMacLease(),
			"openvnet_ip_lease":               OpenVNetIpLease(),
			"openvnet_ip_range_group":         OpenVNetIpRangeGroup(),
			"openvnet_ip_lease_container":     OpenVNetIpLeaseContainer(),
			"openvnet_ip_retention_container": OpenVNetIpRetentionContainer(),
			"openvnet_lease_policy":           OpenVNetLeasePolicy(),
			"openvnet_lease_policy_relation":  OpenVNetLeasePolicyRelation(),
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
