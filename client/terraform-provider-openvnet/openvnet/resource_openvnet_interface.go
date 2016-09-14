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

            "display_name": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },

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
                Optional: true,
            },

            "mac_address": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },

            "ipv4_address": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },

            "port_name": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },

            "mode": &schema.Schema{
                Type:     schema.TypeString,
                Optional: true,
            },

            "security_group": &schema.Schema{
                Type:     schema.TypeSet,
                Optional: true,
                Elem: &schema.Resource{
                    Schema: map[string]*schema.Schema{
                        "security_group_id": &schema.Schema{
                            Type:     schema.TypeString,
                            Optional: true,
                        },

                        "display_name": &schema.Schema{
                            Type:     schema.TypeString,
                            Required: true,
                        },
                    },
                },
            },


        },
    }
}

func openVNetInterfaceCreate(d *schema.ResourceData, m interface{}) error {

    client := m.(*openvnet.Client)

    params := &openvnet.InterfaceCreateParams{
        //DisplayName:d.Get("display_name").(string),
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

    intfc, _, err := client.Interface.Create(params)
    d.SetId(intfc.UUID)


    if x := d.Get("security_group"); x != nil {
        for _, y := range x.(*schema.Set).List() {
            z := y.(map[string]interface{})

            err = createSecurityGroup(client, z)
            if err != nil {
                return err
            }
        }
    }

    return err
}

func openVNetInterfaceRead(d *schema.ResourceData, m interface{}) error {
    client := m.(*openvnet.Client)
    intfc, _, err := client.Interface.GetByUUID(d.Id())

    if err != nil {
        return err
    }

    d.Set("ingress_filtering_enabled", intfc.IngressFilteringEnabled)
    d.Set("enable_routing", intfc.EnableRouting)
    d.Set("enable_route_translation", intfc.EnableRouteTranslation)
    d.Set("enable_filtering", intfc.EnableFiltering)
    d.Set("network_uuid", intfc.NetworkUUID)
    d.Set("mac_address", intfc.MacAddress)    
    d.Set("mode", intfc.Mode)
    d.Set("ipv4_address", IPv4Address)

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

func createSecurityGroup(c *openvnet.Client, theMap map[string]interface{}) error {

    sgroup_params := &openvnet.SecurityGroupCreateParams{
        UUID: theMap["security_group_id"].(string),
        DisplayName:     theMap["display_name"].(string),
    }

    // This could most likely be done in a much better way.
    g, _, err := c.SecurityGroup.Create(sgroup_params)
    if err != nil {
        return fmt.Errorf("Error creating security group: %s", err)
    }
    if g == nil{
        return nil
    }

    return nil
}