package openvnet

import (
        "github.com/hashicorp/terraform/helper/schema"
        "github.com/axsh/openvnet/client/go-openvnet"
 )

func OpenVNetMacRangeGroup() *schema.Resource {
    return &schema.Resource{
        Create: openVNetMacRangeGroupCreate,
        Read:   openVNetMacRangeGroupRead,
        Update: openVNetMacRangeGroupUpdate,
        Delete: openVNetMacRangeGroupDelete,

        Schema: map[string]*schema.Schema{

            "uuid": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },

            "allocation_type": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },

            "mac_range": &schema.Schema{
                Type:     schema.TypeSet,
                Optional: true,
                Elem: &schema.Resource{
                    Schema: map[string]*schema.Schema{
                       "begin_mac_address": &schema.Schema{
                            Type:     schema.TypeString,
                            Optional: true,
                        },

                        "end_mac_address": &schema.Schema{
                            Type:     schema.TypeString,
                            Optional: true,
                        },
                    },
                },
            },
        },
    }
}

func openVNetMacRangeGroupCreate(d *schema.ResourceData, m interface{}) error {

    client := m.(*openvnet.Client)

    params := &openvnet.MacRangeGroupCreateParams{
        UUID:d.Get("uuid").(string),
        AllocationType:d.Get("allocation_type").(string),
    }

    mac_Range_group, _, err := client.MacRangeGroup.Create(params)
    d.SetId(mac_Range_group.UUID)

    return err
}

func openVNetMacRangeGroupRead(d *schema.ResourceData, m interface{}) error {

    client := m.(*openvnet.Client)
    mac_Range_group, _, err := client.MacRangeGroup.GetByUUID(d.Id())

    if err != nil {
        return err
    }

    d.Set("allocation_type", mac_Range_group.AllocationType)


    return nil
}

func openVNetMacRangeGroupUpdate(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetMacRangeGroupDelete(d *schema.ResourceData, m interface{}) error {
    client := m.(*openvnet.Client)
    _, err := client.MacRangeGroup.Delete(d.Id())
    
    return err
}
