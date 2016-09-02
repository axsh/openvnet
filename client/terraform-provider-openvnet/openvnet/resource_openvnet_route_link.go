package main

import (
		"github.com/hashicorp/terraform/helper/schema"
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

	uuid := d.Get("uuid").(string)
    mac_address := d.Get("mac_address").(string)

    return nil
}

func openVNetRouteLinkRead(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetRouteLinkUpdate(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetRouteLinkDelete(d *schema.ResourceData, m interface{}) error {
    return nil
}
