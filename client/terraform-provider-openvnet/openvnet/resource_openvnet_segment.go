package openvnet

import (
	"github.com/axsh/openvnet/client/go-openvnet"
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
				Optional: true,
				Computed: true,
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

	params := &openvnet.SegmentCreateParams{
		UUID: d.Get("uuid").(string),
		Mode: d.Get("mode").(string),
	}

	segment, _, err := client.Segment.Create(params)
	d.SetId(segment.UUID)

	return err
}

func openVNetSegmentRead(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)
	segment, _, err := client.Segment.GetByUUID(d.Id())

	d.Set("mode", segment.Mode)

	return err
}

func openVNetSegmentUpdate(d *schema.ResourceData, m interface{}) error {
	return nil
}

func openVNetSegmentDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)
	_, err := client.Segment.Delete(d.Id())

	return err
}
