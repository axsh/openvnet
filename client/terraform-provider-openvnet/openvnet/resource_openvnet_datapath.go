package openvnet

import (
    "github.com/hashicorp/terraform/helper/schema"
    "github.com/axsh/openvnet/client/go-openvnet"
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
                Optional: true,
                Computed: true,
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

    client := m.(*openvnet.Client)

    params := &openvnet.DatapathCreateParams{
        UUID:d.Get("uuid").(string),
        DisplayName:d.Get("display_name").(string),
        DPID:d.Get("dpid").(string),
        NodeId:d.Get("node_id").(string),
    }

    datapath, _, err := client.Datapath.Create(params)
    d.SetId(datapath.UUID)

    return err
}

func openVNetDatapathRead(d *schema.ResourceData, m interface{}) error {
    
    client := m.(*openvnet.Client)
    datapath, _, err := client.Datapath.GetByUUID(d.Id())

    if err != nil {
        return err
    }

    d.Set("display_name", datapath.DisplayName)
    d.Set("dpid", datapath.DPID)
    d.Set("node_id", datapath.NodeId)
    d.Set("is_connected", datapath.IsConnected)

    return nil
}

func openVNetDatapathUpdate(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetDatapathDelete(d *schema.ResourceData, m interface{}) error {
    
    client := m.(*openvnet.Client)
    _, err := client.Datapath.Delete(d.Id())

    return err
}
