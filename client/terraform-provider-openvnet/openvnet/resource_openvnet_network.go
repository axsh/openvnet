package openvnet

import (
    "github.com/hashicorp/terraform/helper/schema"
    "github.com/axsh/openvnet/client/go-openvnet"
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
                Optional: true,
            },

            "display_name": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },

            "ipv4_network": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },

            "ipv4_prefix": &schema.Schema{
                Type:     schema.TypeInt,
                Optional: true,
            },

            "network_mode": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },

            "domain_name": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },

            "segment_uuid": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },
        },
    }
}

func openVNetNetworkCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

    params := openvnet.NetworkCreateParams{
        UUID:d.Get("uuid").(string),
        DisplayName:d.Get("display_name").(string),
        Ipv4Network:d.Get("ipv4_network").(string),
        Ipv4Prefix:d.Get("ipv4_prefix").(int),
        NetworkMode:d.Get("network_mode").(string),
        DomainName:d.Get("domain_name").(string),
        SegmentUUID:d.Get("segment_uuid").(string),
    }

    network, _, err := client.Network.Create(&params)

    return nil
}

func openVNetNetworkRead(d *schema.ResourceData, m interface{}) error {
    client := m.(*openvnet.Client)
    network, _, err := client.Network.GetByUUID(d.Id())

    if err != nil {
        return err
    }

    d.Set("display_name", network.DisplayName)
    d.Set("ipv4_network", network.Ipv4Network)
    d.Set("ipv4_prefix", network.Ipv4Prefix)
    d.Set("network_mode", network.NetworkMode)
    d.Set("domain_name", network.DomainName)
    d.Set("segment_uuid", network.SegmentID)    

    return nil
}

func openVNetNetworkUpdate(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetNetworkDelete(d *schema.ResourceData, m interface{}) error {
    client := m.(*openvnet.Client)

    _, err := client.Network.Delete(d.Id())
    return err
}
