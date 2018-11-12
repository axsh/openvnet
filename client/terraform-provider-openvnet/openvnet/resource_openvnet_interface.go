package openvnet

import (
	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetInterface() *schema.Resource {
	return &schema.Resource{
		Create: openVNetInterfaceCreate,
		Read:   openVNetInterfaceRead,
		Delete: openVNetInterfaceDelete,

		Schema: map[string]*schema.Schema{

			"display_name": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"ingress_filtering_enabled": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				ForceNew: true,
			},

			"enable_routing": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				ForceNew: true,
			},

			"enable_route_translation": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				ForceNew: true,
			},

			"owner_datapath_uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"enable_filtering": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				ForceNew: true,
			},

			"segment_uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"network_uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"mac_address": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"ipv4_address": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"port_name": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"mode": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},
		},
	}
}

func openVNetInterfaceCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	params := &openvnet.InterfaceCreateParams{
		UUID: d.Get("uuid").(string),
		IngressFilteringEnabled: d.Get("ingress_filtering_enabled").(bool),
		EnableRouting:           d.Get("enable_routing").(bool),
		EnableRouteTranslation:  d.Get("enable_route_translation").(bool),
		OwnerDatapathUUID:       d.Get("owner_datapath_uuid").(string),
		EnableFiltering:         d.Get("enable_filtering").(bool),
		SegmentUUID:             d.Get("segment_uuid").(string),
		NetworkUUID:             d.Get("network_uuid").(string),
		MacAddress:              d.Get("mac_address").(string),
		Ipv4Address:             d.Get("ipv4_address").(string),
		PortName:                d.Get("port_name").(string),
		Mode:                    d.Get("mode").(string),
	}

	intfc, _, err := client.Interface.Create(params)
	d.SetId(intfc.UUID)

	return err
}

func openVNetInterfaceRead(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)
	intfc, _, err := client.Interface.GetByUUID(d.Id())

	if err != nil {
		return err
	}

	d.Set("ingress_filtering_enabled", intfc.IngressFilteringEnabled)
	d.Set("enable_routing", intfc.EnableRouting)
	d.Set("enable_route_translation", intfc.EnableRouteTranslation)
	d.Set("enable_filtering", intfc.EnableFiltering)
	d.Set("network_uuid", intfc.NetworkUUID)
	d.Set("mac_address", intfc.MacAddress)
	d.Set("mode", intfc.Mode)
	d.Set("ipv4_address", intfc.Ipv4Address)

	return nil
}

func openVNetInterfaceDelete(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)
	_, err := client.Interface.Delete(d.Id())

	return err
}
