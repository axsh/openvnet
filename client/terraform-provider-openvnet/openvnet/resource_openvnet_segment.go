package openvnet

import (
    "github.com/hashicorp/terraform/helper/schema"
    "github.com/axsh/openvnet/client/go-openvnet"
    "fmt"
    "log"
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

    client := m.(*openvnet.Client)

    params := openvnet.SegmentCreateParams{
        UUID:  d.Get("UUID").(string),
        Mode:  d.Get("Mode").(string),
    }

    segment, _, err := client.Segment.Create(&params)

    if err != nil {
        return fmt.Errorf("Error creating segment: %s", err)
    }

    d.SetId(segment.ID)
    log.Printf("[INFO] Segment ID: %s", d.Id())

    return nil
}

func openVNetSegmentRead(d *schema.ResourceData, m interface{}) error {

    client := m.(*openvnet.Client)

    segment, _, err := client.Segment.GetByID(d.Id())
    if err != nil {
        return err
    }

    d.Set("uuid", segment.UUID)
    d.Set("mode", segment.Mode)

    return nil
}

func openVNetSegmentUpdate(d *schema.ResourceData, m interface{}) error {
    return nil
}

func openVNetSegmentDelete(d *schema.ResourceData, m interface{}) error {
    client := m.(*openvnet.Client)

    _, err := client.Network.Delete(d.Id())
    return err
}
