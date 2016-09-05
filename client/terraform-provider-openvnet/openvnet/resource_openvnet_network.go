package main

import (
    "github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetNetwork() *schema.Resource {
    return &schema.Resource{
        Create: openVNetNetworkCreate,
        Read:   openVNetNetworkRead,
        Update: openVNetNetworkUpdate,
        Delete: openVNetNetworkDelete,

        Schema: map[string]*schema.Schema{

            "uuid": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },

            "display_name": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },

            "ipv4_network": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },

            "network_mode": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },

            "segment_uuid": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },

            "editable": &schema.Schema{
                Type:     schema.TypeBool,
                Optional: true,
            },
        },
    }
}

func openVNetNetworkCreate(d *schema.ResourceData, m interface{}) error {

	uuid := d.Get("uuid").(string)
    display_name := d.Get("display_name").(string)
    ipv4_network := d.Get("ipv4_network").(string)
    network_mode := d.Get("network_mode").(string)
    segment_uuid := d.Get("segment_uuid").(string)
    editable := d.Get("editable").(bool)

    return nil
}

func openVNetNetworkRead(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetNetworkUpdate(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetNetworkDelete(d *schema.ResourceData, m interface{}) error {
    return nil
}
