package openvnet

import (
	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetLeasePolicy() *schema.Resource {
	return &schema.Resource{
		Create: openVNetLeasePolicyCreate,
		Read:   openVNetLeasePolicyRead,
		Delete: openVNetLeasePolicyDelete,

		Schema: map[string]*schema.Schema{

			"uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"mode": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"timing": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},
		},
	}
}

func openVNetLeasePolicyCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	params := &openvnet.LeasePolicyCreateParams{
		UUID:   d.Get("uuid").(string),
		Mode:   d.Get("mode").(string),
		Timing: d.Get("timing").(string),
	}

	leasePolicy, _, err := client.LeasePolicy.Create(params)
	d.SetId(leasePolicy.UUID)

	return err
}

func openVNetLeasePolicyRead(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)
	leasePolicy, _, err := client.LeasePolicy.GetByUUID(d.Id())

	if err != nil {
		return err
	}

	d.Set("timing", leasePolicy.Timing)
	d.Set("mode", leasePolicy.Mode)

	return nil
}

func openVNetLeasePolicyDelete(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)
	_, err := client.LeasePolicy.Delete(d.Id())

	return err
}
