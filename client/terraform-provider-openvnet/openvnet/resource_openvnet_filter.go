package openvnet

import (
	"fmt"

	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetFilter() *schema.Resource {
	return &schema.Resource{
		Create: openVNetFilterCreate,
		Read:   openVNetFilterRead,
		Delete: openVNetFilterDelete,

		Schema: map[string]*schema.Schema{

			"uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"mode": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"interface_uuid": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"ingress_passthrough": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				ForceNew: true,
			},

			"egress_passthrough": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				ForceNew: true,
			},
			"static": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"protocol": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							ForceNew: true,
						},

						"action": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							ForceNew: true,
						},

						"src_address": &schema.Schema{
							Type: schema.TypeString,
							// Optional: true,
							ForceNew: true,
							Computed: true,
						},

						"dst_address": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							ForceNew: true,
							Computed: true,
						},

						"src_port": &schema.Schema{
							Type:     schema.TypeInt,
							Optional: true,
							ForceNew: true,
							Computed: true,
						},

						"dst_port": &schema.Schema{
							Type:     schema.TypeInt,
							Optional: true,
							ForceNew: true,
							Computed: true,
						},
					},
				},
			},
		},
	}
}

func openVNetFilterCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	params := &openvnet.FilterCreateParams{
		UUID:               d.Get("uuid").(string),
		InterfaceUUID:      d.Get("interface_uuid").(string),
		Mode:               d.Get("mode").(string),
		EgressPassthrough:  d.Get("egress_passthrough").(bool),
		IngressPassthrough: d.Get("ingress_passthrough").(bool),
	}

	filter, _, err := client.Filter.Create(params)
	if err != nil {
		return fmt.Errorf("failed to create filter: %v", err)
	}

	if statics := d.Get("static").([]interface{}); statics[:len(statics)-1] != nil {
		for _, static := range statics {
			params := static.(map[string]interface{})
			_, _, err := client.Filter.CreateStatic(filter.UUID, &openvnet.FilterStaticCreateParams{
				Protocol:   params["protocol"].(string),
				Action:     params["action"].(string),
				SrcAddress: params["src_address"].(string),
				DstAddress: params["dst_address"].(string),
				SrcPort:    params["src_port"].(int),
				DstPort:    params["dst_port"].(int),
			})

			if err != nil {
				return fmt.Errorf("faield to create static filter: %v", err)
			}
		}
	}

	d.SetId(filter.UUID)
	return openVNetFilterRead(d, m)
}

func openVNetFilterRead(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)
	filter, _, err := client.Filter.GetByUUID(d.Id())

	if err != nil {
		return err
	}

	d.Set("mode", filter.Mode)
	d.Set("ingress_passthrough", filter.IngressPassthrough)
	d.Set("egress_passthrough", filter.EgressPassthrough)

	staticsList, _, err := client.Filter.GetStatic(d.Id())
	if err != nil {
		return fmt.Errorf("failed to read list of statics")
	}

	statics := make([]map[string]interface{}, len(staticsList.Items))
	// if statics := d.Get("static").([]interface{}); statics[:len(statics)-1] != nil {
	for i, static := range staticsList.Items {
		statics[i] = make(map[string]interface{})
		statics[i]["protocol"] = static.Protocol
		statics[i]["action"] = static.Action
		statics[i]["src_address"] = static.SrcAddress
		statics[i]["dst_address"] = static.DstAddress
		statics[i]["src_port"] = static.SrcPort
		statics[i]["dst_port"] = static.DstPort
	}
	d.Set("static", statics)
	// }
	return nil
}

func openVNetFilterDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)
	_, err := client.Filter.Delete(d.Id())

	return err
}
