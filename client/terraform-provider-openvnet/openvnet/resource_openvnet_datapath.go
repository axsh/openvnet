package openvnet

import (
    "github.com/hashicorp/terraform/helper/schema"
    "github.com/axsh/openvnet/client/go-openvnet"
    "fmt"
    "log"
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

    client := m.(*openvnet.Client)

    params := openvnet.DatapathCreateParams{
        UUID:d.Get("uuid").(string),
        DisplayName:d.Get("display_name").(string),
        DPID:d.Get("dpid").(string),
        NodeID:d.Get("node_id").(string),
    }

    datapath, _, err := client.Datapath.Create(&params)

    if err != nil {
        return fmt.Errorf("Error creating datapath: %s", err)
    }

    d.SetId(datapath.ID)
    log.Printf("[INFO] Datapath Id: %s", d.Id())

    return nil
}

func openVNetDatapathRead(d *schema.ResourceData, m interface{}) error {
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