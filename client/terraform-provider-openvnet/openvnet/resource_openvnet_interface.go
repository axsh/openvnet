package main

import "github.com/hashicorp/terraform/helper/schema"

func OpenVNetInterface() *schema.Resource {
    return &schema.Resource{
        Create: openVNetInterfaceCreate,
        Read:   openVNetInterfaceRead,
        Update: openVNetInterfaceUpdate,
        Delete: openVNetInterfaceDelete,

        Schema: map[string]*schema.Schema{

            "display_name": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },

            "uuid": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
                ForceNew: true,
            },

            "mode": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },

            "ipv4_address": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },

            "mac_address": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
                ForceNew: true,
            },

            "network_uuid": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },

            "segment_uuid": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },

            "port_name": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },

            "ingress_filtering_enable": &schema.Schema{
                Type:     schema.TypeBool,
                Required: true,
            },

            "enable_route_translations": &schema.Schema{
                Type:     schema.TypeBool,
                Required: true,
            },

            "enable_filtering": &schema.Schema{
                Type:     schema.TypeBool,
                Required: true,
            },

            "enable_routing": &schema.Schema{
                Type:     schema.TypeBool,
                Required: true,
            },

            "port": &schema.Schema{
                Type:     schema.TypeList,
                Optional: true,
                Elem: &schema.Resource{
                    Schema: map[string]*schema.Schema{

                        "datapath_uuid": &schema.Schema{
                            Type:     schema.TypeString,
                            Optional: true,
                        },

                        "port_name": &schema.Schema{
                            Type:     schema.TypeString,
                            Optional: true,
                            ForceNew: true,
                        },

                        "singular": &schema.Schema{
                            Type:     schema.TypeString,
                            Optional: true,
                            ForceNew: true,
                        },
                    },
                },
            },

            "security_group": &schema.Schema{
                Type:     schema.TypeList,
                Optional: true,
                Elem: &schema.Resource{
                    Schema: map[string]*schema.Schema{

                        "security_group_id": &schema.Schema{
                            Type:     schema.TypeString,
                            Optional: true,
                        },
                    },
                },
            },
        },
    }
}

func openVNetInterfaceCreate(d *schema.ResourceData, m interface{}) error {

	display_name := d.Get("display_name").(string)
    uuid := d.Get("uuid").(string)
    mode := d.Get("mode").(string)
    ipv4_address := d.Get("ipv4_address").(string)
    mac_address := d.Get("mac_address").(string)
    network_uuid := d.Get("network_uuid").(string)
    segment_uuid := d.Get("segment_uuid").(string)
    port_name := d.Get("port_name").(string)

    ingress_filtering_enable := d.Get("ingress_filtering_enable").(bool)
    enable_route_translations := d.Get("enable_route_translations").(bool)
    enable_filtering := d.Get("enable_filtering").(bool)
    enable_routing := d.Get("enable_routing").(bool)

    return nil
}

func openVNetInterfaceRead(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetInterfaceUpdate(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetInterfaceDelete(d *schema.ResourceData, m interface{}) error {
    return nil
}