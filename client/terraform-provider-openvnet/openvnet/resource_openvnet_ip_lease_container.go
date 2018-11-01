package openvnet

import (
	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetIpLeaseContainer() *schema.Resource {
	return &schema.Resource{
		Create: openVNetIpLeaseContainerCreate,
		Read:   openVNetIpLeaseContainerRead,
		Delete: openVNetIpLeaseContainerDelete,

		Schema: map[string]*schema.Schema{

			"ip_lease_container_uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},
		},
	}
}

func openVNetIpLeaseContainerCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	params := &openvnet.IpLeaseCreateParams{
		UUID: d.Get("ip_lease_container_uuid").(string),
	}

	ipLeaseContainer, _, err := client.IpLeaseContainer.Create(params)
	d.SetId(ipLeaseContainer.UUID)

	return err
}

func openVNetIpLeaseContainerRead(d *schema.ResourceData, m interface{}) error {
	return nil
}

func openVNetIpLeaseContainerDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)
	_, err := client.IpLeaseContainer.Delete(d.Id())

	return err
}
