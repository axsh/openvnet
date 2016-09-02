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

            "network": &schema.Schema{
                Type:     schema.TypeList,
                Optional: true,
                Elem: &schema.Resource{
                    Schema: map[string]*schema.Schema{

                        "mac_address": &schema.Schema{
                            Type:     schema.TypeString,
                            ForceNew: true,
                        },

                        "interface_uuid": &schema.Schema{
                            Type:     schema.TypeString,
                            Optional: true,
                            ForceNew: true,
                        },
                    },
                },
            },

            "route_link": &schema.Schema{
                Type:     schema.TypeList,
                Optional: true,
                Elem: &schema.Resource{
                    Schema: map[string]*schema.Schema{

                        "mac_address": &schema.Schema{
                            Type:     schema.TypeString,
                            ForceNew: true,
                        },

                        "interface_uuid": &schema.Schema{
                            Type:     schema.TypeString,
                            Optional: true,
                            ForceNew: true,
                        },
                    },
                },
            },

            "segment": &schema.Schema{
                Type:     schema.TypeList,
                Optional: true,
                Elem: &schema.Resource{
                    Schema: map[string]*schema.Schema{
                    	
                        "mac_address": &schema.Schema{
                            Type:     schema.TypeString,
                            ForceNew: true,
                        },

                        "interface_uuid": &schema.Schema{
                            Type:     schema.TypeString,
                            Optional: true,
                            ForceNew: true,
                        },
                    },
                },
            },
        },
    }
}

func openVNetDatapathCreate(d *schema.ResourceData, m interface{}) error {

    display_name := d.Get("display_name").(string)
    uuid := d.Get("uuid").(string)
    dpid := d.Get("dpid").(string)
    node_id := d.Get("node_id").(string)

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