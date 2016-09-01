package main

import (
    "github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetDatapath() *schema.Resource {
    return &schema.Resource{
        Create: openVNetDatapathCreate,
        Read:   openVNetDatapathRead,
        Update: openVNetDatapathUpdate,
        Delete: openVNetDatapathDelete,

        Schema: map[string]*schema.Schema{
            "display_name": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },

            "uuid": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },
            "dpid": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },
            "node_id": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },
        },
    }
}

func openVNetDatapathCreate(d *schema.ResourceData, m interface{}) error {
    display_name := d.Get("display_name").(string)
    uuid := d.Get("uuid").(string)
    dpid := d.Get("dpid").(string)
    node_id := d.Get("node_id").(string)

    d.SetId(display_name + "!")
    d.SetId(uuid + "!")
    d.SetId(dpid + "!")
    d.SetId(node_id + "!")

    return nil
}

func openVNetDatapathRead(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetDatapathUpdate(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetDatapathDelete(d *schema.ResourceData, m interface{}) error {
    return nil
}