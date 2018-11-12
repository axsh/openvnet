package openvnet

import (
	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetIpRetentionContainer() *schema.Resource {
	return &schema.Resource{
		Create: openVNetIpRetentionContainerCreate,
		Read:   openVNetIpRetentionContainerRead,
		Delete: openVNetIpRetentionContainerDelete,

		Schema: map[string]*schema.Schema{

			"uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"lease_time": &schema.Schema{
				Type:     schema.TypeInt,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"grace_time": &schema.Schema{
				Type:     schema.TypeInt,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},
		},
	}
}

func openVNetIpRetentionContainerCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	params := &openvnet.IpRetentionContainerCreateParams{
		UUID:      d.Get("uuid").(string),
		LeaseTime: d.Get("lease_time").(int),
		GraceTime: d.Get("grace_time").(int),
	}

	ipRetentionContainer, _, err := client.IpRetentionContainer.Create(params)
	d.SetId(ipRetentionContainer.UUID)

	return err
}

func openVNetIpRetentionContainerRead(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)
	ipRetentionContainer, _, err := client.IpRetentionContainer.GetByUUID(d.Id())

	d.Set("lease_time", ipRetentionContainer.LeaseTime)
	d.Set("grace_time", ipRetentionContainer.GraceTime)

	return err
}

func openVNetIpRetentionContainerDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)
	_, err := client.IpRetentionContainer.Delete(d.Id())

	return err
}