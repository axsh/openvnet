package main

import (
    "github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetNetwork() *schema.Resource {
    return &schema.Resource{
        Create: openVNetNetworkCreate,
        Read:   openVNetNetworkRead,
        Update: openVNetNetworkUpdate,
        Delete: openVNetNetworkDelete,

        Schema: map[string]*schema.Schema{
          
        },
    }
}

func openVNetNetworkCreate(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetNetworkRead(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetNetworkUpdate(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetNetworkDelete(d *schema.ResourceData, m interface{}) error {
    return nil
}
