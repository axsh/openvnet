package openvnet

import (
	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetIpLease() *schema.Resource {
	return &schema.Resource{
		Create: openVNetIpLeaseCreate,
		Read:   openVNetIpLeaseRead,
		Delete: openVNetIpLeaseDelete,

		Schema: map[string]*schema.Schema{

			"uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"ipv4_address": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"network_uuid": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"interface_uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"mac_lease_uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"enable_routing": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				ForceNew: true,
			},
		},
	}
}

func openVNetIpLeaseCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	params := &openvnet.IpLeaseCreateParams{
		UUID:          d.Get("uuid").(string),
		IPv4Address:   d.Get("ipv4_address").(string),
		NetworkUUID:   d.Get("network_uuid").(string),
		EnableRouting: d.Get("enable_routing").(bool),
		MacLeaseUUID:  d.Get("mac_lease_uuid").(string),
		InterfaceUUID: d.Get("interface_uuid").(string),
	}

	ipLease, _, err := client.IpLease.Create(params)
	d.SetId(ipLease.UUID)

	return err
}

func openVNetIpLeaseRead(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)
	ipLease, _, err := client.IpLease.GetByUUID(d.Id())

	d.Set("network_uuid", ipLease.NetworkID)
	d.Set("ipv4_address", ipLease.IPv4Address)
	d.Set("enable_routing", ipLease.EnableRouting)
	d.Set("interface_uuid", ipLease.InterfaceID)
	d.Set("mac_lease_uuid", ipLease.MacLeaseID)
	return err
}

func openVNetIpLeaseDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)
	_, err := client.IpLease.Delete(d.Id())

	return err
}
