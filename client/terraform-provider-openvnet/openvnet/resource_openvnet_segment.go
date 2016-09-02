package main

import (
    "github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetSegment() *schema.Resource {
    return &schema.Resource{
        Create: openVNetSegmentCreate,
        Read:   openVNetSegmentRead,
        Update: openVNetSegmentUpdate,
        Delete: openVNetSegmentDelete,

        Schema: map[string]*schema.Schema{

        	"uuid": &schema.Schema{
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

func openVNetSegmentCreate(d *schema.ResourceData, m interface{}) error {

	uuid := d.Get("uuid").(string)
    mode := d.Get("mode").(string)
	
    return nil
}

func openVNetSegmentRead(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetSegmentUpdate(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetSegmentDelete(d *schema.ResourceData, m interface{}) error {
    return nil
}
