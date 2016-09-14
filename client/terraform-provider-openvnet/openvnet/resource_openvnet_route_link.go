package openvnet

import (
		"github.com/hashicorp/terraform/helper/schema"
        "github.com/axsh/openvnet/client/go-openvnet"
 )

func OpenVNetRouteLink() *schema.Resource {
    return &schema.Resource{
        Create: openVNetRouteLinkCreate,
        Read:   openVNetRouteLinkRead,
        Update: openVNetRouteLinkUpdate,
        Delete: openVNetRouteLinkDelete,

        Schema: map[string]*schema.Schema{

        	"uuid": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            },

            "mac_address": &schema.Schema{
                Type:     schema.TypeString,
                Required: true,
            }, 
        },
    }
}

func openVNetRouteLinkCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

    params := &openvnet.RouteLinkCreateParams{
        UUID:d.Get("uuid").(string),
        MacAddress:d.Get("mac_address").(string),
    }

    routelink, _, err := client.RouteLink.Create(params)
    d.SetId(routelink.UUID)

    return err
}

func openVNetRouteLinkRead(d *schema.ResourceData, m interface{}) error {
    client := m.(*openvnet.Client)
    routelink, _, err := client.RouteLink.GetByUUID(d.Id())

    if err != nil {
        return err
    }

    d.Set("mac_address", routelink.MacAddress)


    return nil
}

func openVNetRouteLinkUpdate(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetRouteLinkDelete(d *schema.ResourceData, m interface{}) error {
    client := m.(*openvnet.Client)
    _, err := client.RouteLink.Delete(d.Id())
    
    return err
}
