package openvnet

import (
    "github.com/hashicorp/terraform/helper/schema"
    "github.com/axsh/openvnet/client/go-openvnet"
)

func OpenVNetInterface() *schema.Resource {
    return &schema.Resource{
        Create: openVNetInterfaceCreate,
        Read:   openVNetInterfaceRead,
        Update: openVNetInterfaceUpdate,
        Delete: openVNetInterfaceDelete,

        Schema: map[string]*schema.Schema{

            "uuid": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },

            "ingress_filtering_enabled": &schema.Schema{
                Type:     schema.TypeBool,
                Optional: true,
            },

            "enable_routing": &schema.Schema{
                Type:     schema.TypeBool,
                Optional: true,
            },

            "enable_route_translation": &schema.Schema{
                Type:     schema.TypeBool,
                Optional: true,
            },

            "owner_datapath_id": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },

            "enable_filtering": &schema.Schema{
                Type:     schema.TypeBool,
                Optional: true,
            },

            "segment_uuid": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },

            "network_uuid": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },

            "mac_address": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },

            "ipv4_address": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },

            "port_name": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },

            "mode": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },
        },
    }
}

func openVNetInterfaceCreate(d *schema.ResourceData, m interface{}) error {

    client := m.(*openvnet.Client)

    params := openvnet.InterfaceCreateParams{
        UUID:d.Get("UUID").(string),
        IngressFilteringEnabled:d.Get("ingress_filtering_enabled").(bool),
        EnableRouting:d.Get("EnableRouting").(bool),
        EnableRouteTranslation:d.Get("EnableRouteTranslation").(bool),
        OwnerDatapathID:d.Get("OwnerDatapathID").(string),
        EnableFiltering:d.Get("EnableFiltering").(bool),
        SegmentUUID:d.Get("SegmentUUID").(string),
        NetworkUUID:d.Get("NetworkUUID").(string),
        MacAddress:d.Get("MacAddress").(string),
        Ipv4Address:d.Get("Ipv4Address").(string),
        PortName:d.Get("PortName").(string),
        Mode:d.Get("Mode").(string),
    }

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