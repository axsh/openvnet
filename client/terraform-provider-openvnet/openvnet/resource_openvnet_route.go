package main

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

	uuid := d.Get("uuid").(string)
    interface_uuid := d.Get("interface_uuid").(string)
    route_link_uuid := d.Get("route_link_uuid").(string)
    network_uuid := d.Get("network_uuid").(string)
    ipv4_network := d.Get("ipv4_network").(string)
    ipv4_prefix := d.Get("ipv4_prefix").(int)
    ingress := d.Get("ingress").(string)
    egress := d.Get("egress").(string)

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
