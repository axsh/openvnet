package main

import "github.com/hashicorp/terraform/helper/schema"


func OpenVNetInterface() *schema.Resource {
    return &schema.Resource{
        Create: openVNetInterfaceCreate,
        Read:   openVNetInterfaceRead,
        Update: openVNetInterfaceUpdate,
        Delete: openVNetInterfaceDelete,

        Schema: map[string]*schema.Schema{
            
        },
    }
}

func openVNetInterfaceCreate(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetInterfaceRead(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetInterfaceUpdate(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetInterfaceDelete(d *schema.ResourceData, m interface{}) error {
    return nil
}