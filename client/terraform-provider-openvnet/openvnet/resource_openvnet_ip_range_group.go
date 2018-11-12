package openvnet

import (
	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetIpRangeGroup() *schema.Resource {
	return &schema.Resource{
		Create: openVNetIpRangeGroupCreate,
		Read:   openVNetIpRangeGroupRead,
		Delete: openVNetIpRangeGroupDelete,

		Schema: map[string]*schema.Schema{

			"uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"allocation_type": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"ip_range": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"uuid": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							Computed: true,
							ForceNew: true,
						},

						"begin_ipv4_address": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							Computed: true,
							ForceNew: true,
						},

						"end_ipv4_address": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							Computed: true,
							ForceNew: true,
						},
					},
				},
			},
		},
	}
}

func openVNetIpRangeGroupCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	params := &openvnet.IpRangeGroupCreateParams{
		UUID:           d.Get("uuid").(string),
		AllocationType: d.Get("allocation_type").(string),
	}

	ipRangeGroup, _, err := client.IpRangeGroup.Create(params)
	if err != nil {
		return err
	}

	d.SetId(ipRangeGroup.UUID)

	if ipr := d.Get("ip_range"); ipr != nil {
		for _, ipRanges := range ipr.([]interface{}) {
			ipRangeMap := ipRanges.(map[string]interface{})

			ipRange := &openvnet.IpRangeCreateParams{
				BeginIpv4Address: ipRangeMap["begin_ipv4_address"].(string),
				EndIpv4Address:   ipRangeMap["end_ipv4_address"].(string),
			}

			client.IpRangeGroup.CreateRange(d.Id(), ipRange)
		}
	}

	return openVNetIpRangeGroupRead(d, m)
}

func openVNetIpRangeGroupRead(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)
	ipRangeGroup, _, err := client.IpRangeGroup.GetByUUID(d.Id())

	d.Set("allocation_type", ipRangeGroup.AllocationType)

	ipRange, _, err := client.IpRangeGroup.GetRange(d.Id())
	ipRanges := make([]map[string]interface{}, len(ipRange.Items))

	for i, ipr := range ipRange.Items {
		ipRanges[i] = make(map[string]interface{})
		ipRanges[i]["uuid"] = ipr.UUID
		ipRanges[i]["begin_ipv4_address"] = ipr.BeginIpv4Address
		ipRanges[i]["end_ipv4_address"] = ipr.EndIpv4Address
	}
	d.Set("ip_range", ipRanges)

	return err
}

func openVNetIpRangeGroupDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)

	if ipr := d.Get("ip_range"); ipr != nil {
		for _, ipRanges := range ipr.([]interface{}) {
			ipRange := ipRanges.(map[string]interface{})
			client.IpRangeGroup.DeleteRange(d.Id(), ipRange["uuid"].(string))
		}
	}

	_, err := client.IpRangeGroup.Delete(d.Id())

	return err
}
