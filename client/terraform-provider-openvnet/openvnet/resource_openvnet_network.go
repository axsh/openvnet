package openvnet

import (
	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetNetwork() *schema.Resource {
	return &schema.Resource{
		Create: openVNetNetworkCreate,
		Read:   openVNetNetworkRead,
		Delete: openVNetNetworkDelete,

		Schema: map[string]*schema.Schema{

			"uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"display_name": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"ipv4_network": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"ipv4_prefix": &schema.Schema{
				Type:     schema.TypeInt,
				Optional: true,
				ForceNew: true,
			},

			"mode": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"domain_name": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"segment_uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},
		},
	}
}

func openVNetNetworkCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	params := &openvnet.NetworkCreateParams{
		UUID:        d.Get("uuid").(string),
		DisplayName: d.Get("display_name").(string),
		Ipv4Network: d.Get("ipv4_network").(string),
		Ipv4Prefix:  d.Get("ipv4_prefix").(int),
		Mode:        d.Get("mode").(string),
		DomainName:  d.Get("domain_name").(string),
		SegmentUUID: d.Get("segment_uuid").(string),
	}

	network, _, err := client.Network.Create(params)
	d.SetId(network.UUID)

	return err
}

func openVNetNetworkRead(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)
	network, _, err := client.Network.GetByUUID(d.Id())

	if err != nil {
		return err
	}

	d.Set("display_name", network.DisplayName)
	d.Set("ipv4_network", network.Ipv4Network)
	d.Set("ipv4_prefix", network.Ipv4Prefix)
	d.Set("mode", network.Mode)
	d.Set("domain_name", network.DomainName)
	d.Set("segment_uuid", network.SegmentID)

	return nil
}

func openVNetNetworkDelete(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)
	_, err := client.Network.Delete(d.Id())

	return err
}
