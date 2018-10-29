package openvnet

import (
	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetMacLease() *schema.Resource {
	return &schema.Resource{
		Create: openVNetMacLeaseCreate,
		Read:   openVNetMacLeaseRead,
		Delete: openVNetMacLeaseDelete,

		Schema: map[string]*schema.Schema{

			"uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"mac_address": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"segment_uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"interface_uuid": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},
		},
	}
}

func openVNetMacLeaseCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	params := &openvnet.MacLeaseCreateParams{
		UUID:          d.Get("uuid").(string),
		MacAddress:    d.Get("mac_address").(string),
		InterfaceUUID: d.Get("interface_uuid").(string),
		SegmentUUID:   d.Get("segment_uuid").(string),
	}

	macLease, _, err := client.MacLease.Create(params)
	d.SetId(macLease.UUID)

	return err
}

func openVNetMacLeaseRead(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)
	macLease, _, err := client.MacLease.GetByUUID(d.Id())

	d.Set("interface_uuid", macLease.InterfaceUUID)
	d.Set("mac_address", macLease.MacAddress)
	d.Set("segment_uuid", macLease.SegmentID)
	return err
}

func openVNetMacLeaseDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)
	_, err := client.MacLease.Delete(d.Id())

	return err
}
