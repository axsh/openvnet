package openvnet

import (
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
            },

            "interface_uuid": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },

            "route_link_uuid": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },

            "network_uuid": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
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
                Type:     schema.TypeString,
                Optional: true,
            },

            "egress": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },
        },
    }
}

func openVNetRouteCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

    params := openvnet.InterfaceCreateParams{
        UUID:d.Get("uuid").(string),
        InterfaceUUID:d.Get("interface_uuid").(bool),
        RouteLinkUUID:d.Get("route_link_uuid").(bool),
        NetworkUUID:d.Get("network_uuid").(bool),
        Ipv4Network:d.Get("ipv4_network").(string),
        Ipv4Prefix:d.Get("ipv4_prefix").(bool),
        Ingress:d.Get("ingress").(string),
        Egress:d.Get("egress").(string),
    }

    route, _, err := client.Route.Create(&params)

    return nil
}

func openVNetRouteRead(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetRouteUpdate(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetRouteDelete(d *schema.ResourceData, m interface{}) error {
    return nil
}
