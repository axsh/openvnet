package openvnet

import (
	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetRoute() *schema.Resource {
	return &schema.Resource{
		Create: openVNetRouteCreate,
		Read:   openVNetRouteRead,
		Update: openVNetRouteUpdate,
		Delete: openVNetRouteDelete,

		Schema: map[string]*schema.Schema{

			"uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
			},

			"interface_uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"route_link_uuid": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},

			"network_uuid": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},

			"ipv4_network": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"ipv4_prefix": &schema.Schema{
				Type:     schema.TypeInt,
				Optional: true,
			},

			"ingress": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
			},

			"egress": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
			},
		},
	}
}

func openVNetRouteCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	params := &openvnet.RouteCreateParams{
		UUID:          d.Get("uuid").(string),
		InterfaceUUID: d.Get("interface_uuid").(string),
		RouteLinkUUID: d.Get("route_link_uuid").(string),
		NetworkUUID:   d.Get("network_uuid").(string),
		Ipv4Network:   d.Get("ipv4_network").(string),
		Ipv4Prefix:    d.Get("ipv4_prefix").(int),
		Ingress:       d.Get("ingress").(bool),
		Egress:        d.Get("egress").(bool),
	}

	route, _, err := client.Route.Create(params)
	d.SetId(route.UUID)

	return err
}

func openVNetRouteRead(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)
	route, _, err := client.Route.GetByUUID(d.Id())

	d.Set("interface_uuid", route.InterfaceUUID)
	d.Set("route_link_uuid", route.RouteLinkUUID)
	d.Set("network_uuid", route.NetworkUUID)
	d.Set("ipv4_network", route.Ipv4Network)
	d.Set("ipv4_prefix", route.Ipv4Prefix)
	d.Set("ingress", route.Ingress)
	d.Set("egress", route.Egress)

	return err
}

func openVNetRouteUpdate(d *schema.ResourceData, m interface{}) error {
	return nil
}

func openVNetRouteDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)
	_, err := client.Route.Delete(d.Id())

	return err
}
