package openvnet

import (
	"strconv"

	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetMacRangeGroup() *schema.Resource {
	return &schema.Resource{
		Create: openVNetMacRangeGroupCreate,
		Read:   openVNetMacRangeGroupRead,
		Update: openVNetMacRangeGroupUpdate,
		Delete: openVNetMacRangeGroupDelete,

		Schema: map[string]*schema.Schema{

			"uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
			},

			"allocation_type": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},

			"mac_range": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"uuid": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							Computed: true,
						},

						"begin_mac_address": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							Computed: true,
						},

						"end_mac_address": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							Computed: true,
						},
					},
				},
			},
		},
	}
}

func openVNetMacRangeGroupCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	params := &openvnet.MacRangeGroupCreateParams{
		UUID:           d.Get("uuid").(string),
		AllocationType: d.Get("allocation_type").(string),
	}

	mac_Range_group, _, err := client.MacRangeGroup.Create(params)
	if err != nil {
		return err
	}

	d.SetId(mac_Range_group.UUID)

	if mr := d.Get("mac_range"); mr != nil {
		for _, macRanges := range mr.([]interface{}) {
			macRangeMap := macRanges.(map[string]interface{})

			macRange := &openvnet.MacRangeCreateParams{
				BeginMacAddress: macRangeMap["begin_mac_address"].(string),
				EndMacAddress:   macRangeMap["end_mac_address"].(string),
			}

			client.MacRangeGroup.CreateRange(d.Id(), macRange)
		}
	}

	return openVNetMacRangeGroupRead(d, m)
}

func openVNetMacRangeGroupRead(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)
	mac_Range_group, _, err := client.MacRangeGroup.GetByUUID(d.Id())

	d.Set("allocation_type", mac_Range_group.AllocationType)

	macRange, _, err := client.MacRangeGroup.GetRange(d.Id())
	macRanges := make([]map[string]interface{}, len(macRange.Items))

	for i, mr := range macRange.Items {
		macRanges[i] = make(map[string]interface{})
		macRanges[i]["uuid"] = mr.UUID
		macRanges[i]["begin_mac_address"] = strconv.Itoa(mr.BeginMacAddress)
		macRanges[i]["end_mac_address"] = strconv.Itoa(mr.EndMacAddress)
	}
	d.Set("mac_range", macRanges)

	return err
}

func openVNetMacRangeGroupUpdate(d *schema.ResourceData, m interface{}) error {
	return nil
}

func openVNetMacRangeGroupDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)

	if mr := d.Get("mac_range"); mr != nil {
		for _, macRanges := range mr.([]interface{}) {
			macRange := macRanges.(map[string]interface{})
			client.MacRangeGroup.DeleteRange(d.Id(), macRange["uuid"].(string))
		}
	}

	_, err := client.MacRangeGroup.Delete(d.Id())

	return err
}
