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
        UUID:d.Get("uuid").(string),
        IngressFilteringEnabled:d.Get("ingress_filtering_enabled").(bool),
        EnableRouting:d.Get("enable_routing").(bool),
        EnableRouteTranslation:d.Get("enable_route_translation").(bool),
        OwnerDatapathID:d.Get("owner_datapath_id").(string),
        EnableFiltering:d.Get("enable_filtering").(bool),
        SegmentUUID:d.Get("segment_uuid").(string),
        NetworkUUID:d.Get("network_uuid").(string),
        MacAddress:d.Get("mac_address").(string),
        Ipv4Address:d.Get("ipv4_address").(string),
        PortName:d.Get("port_name").(string),
        Mode:d.Get("mode").(string),
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
    client := m.(*openvnet.Client)

    _, err := client.Interface.Delete(d.Id())
    return err
}