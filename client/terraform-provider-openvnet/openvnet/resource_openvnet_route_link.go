package main

import "github.com/hashicorp/terraform/helper/schema"


func OpenVNetRouteLink() *schema.Resource {
    return &schema.Resource{
        Create: openVNetRouteLinkCreate,
        Read:   openVNetRouteLinkRead,
        Update: openVNetRouteLinkUpdate,
        Delete: openVNetRouteLinkDelete,

        Schema: map[string]*schema.Schema{
            
        },
    }
}

func openVNetRouteLinkCreate(d *schema.ResourceData, m interface{}) error {
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
