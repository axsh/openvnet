package main

import (
    "github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetRoute() *schema.Resource {
    return &schema.Resource{
        Create: openVNetRouteCreate,
        Read:   openVNetRouteRead,
        Update: openVNetRouteUpdate,
        Delete: openVNetRouteDelete,

        Schema: map[string]*schema.Schema{
            
        },
    }
}

func openVNetRouteCreate(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetRouteRead(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetRouteUpdate(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetRouteDelete(d *schema.ResourceData, m interface{}) error {
    return nil
}
