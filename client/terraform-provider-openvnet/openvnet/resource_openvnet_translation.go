package openvnet

import (
	"fmt"

	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetTranslation() *schema.Resource {
	return &schema.Resource{
		Create: openVNetTranslationCreate,
		Read:   openVNetTranslationRead,
		Delete: openVNetTranslationDelete,

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

			"passthrough": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				ForceNew: true,
			},

			"static_address": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"route_link_uuid": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							ForceNew: true,
						},

						"ingress_ipv4_address": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
							ForceNew: true,
						},

						"egress_ipv4_address": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
							ForceNew: true,
						},

						"ingress_port_number": &schema.Schema{
							Type:     schema.TypeInt,
							Optional: true,
							ForceNew: true,
							Computed: true,
						},

						"egress_port_number": &schema.Schema{
							Type:     schema.TypeInt,
							Optional: true,
							ForceNew: true,
							Computed: true,
						},

						"ingress_network_uuid": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							ForceNew: true,
							Computed: true,
						},

						"egress_network_uuid": &schema.Schema{
							Type:     schema.TypeString,
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

func openVNetTranslationCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	params := &openvnet.TranslationCreateParams{
		UUID:          d.Get("uuid").(string),
		InterfaceUUID: d.Get("interface_uuid").(string),
		Mode:          d.Get("mode").(string),
		Passthrough:   d.Get("passthrough").(bool),
	}

	translation, _, err := client.Translation.Create(params)
	if err != nil {
		return fmt.Errorf("failed to create translation: %v", err)
	}

	if staticAddrs := d.Get("static_address").([]interface{}); staticAddrs[:len(staticAddrs)-1] != nil {
		for _, staticAddr := range staticAddrs {
			params := staticAddr.(map[string]interface{})
			_, _, err := client.Translation.CreateRelation("static_address", &openvnet.TranslationStaticCreateParams{
				TranslationUUID:    translation.UUID,
				RouteLinkUUID:      params["route_link_uuid"].(string),
				IngressIpv4Address: params["ingress_ipv4_address"].(string),
				EgressIpv4Address:  params["egress_ipv4_address"].(string),
				IngressPortNumber:  params["ingress_port_number"].(int),
				EgressPortNumber:   params["egress_port_number"].(int),
				IngressNetworkUUID: params["ingress_network_uuid"].(string),
				EgressNetworkUUID:  params["egress_network_uuid"].(string),
			}, translation.UUID)

			if err != nil {
				return fmt.Errorf("faield to create static address translation: %v", err)
			}
		}
	}

	d.SetId(translation.UUID)
	return openVNetTranslationRead(d, m)
}

func openVNetTranslationRead(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)
	translation, _, err := client.Translation.GetByUUID(d.Id())

	if err != nil {
		return err
	}

	d.Set("mode", translation.Mode)
	d.Set("passthrough", translation.Passthrough)

	// resp, _, err := client.Translation.GetRelations("static_address", translation.UUID)
	// if err != nil {
	// 	return fmt.Errorf("failed to read list of static addresses")
	// }
	// staticAddrList := resp.(*openvnet.TranslationStaticAddressList)
	// staticAddrs := make([]map[string]interface{}, len(staticAddrList.Items))
	// for i, staticAddr := range staticAddrList.Items {
	// 	staticAddrs[i] = make(map[string]interface{})
	// 	staticAddrs[i]["ingress_ipv4_address"] = staticAddr.IngressIpv4Address
	// 	staticAddrs[i]["egress_ipv4_address"] = staticAddr.EgressIpv4Address
	// 	staticAddrs[i]["ingress_port_number"] = staticAddr.IngressPortNumber
	// 	staticAddrs[i]["egerss_port_number"] = staticAddr.EgressPortNumber
	// }
	// d.Set("static_address", staticAddrs)
	return nil
}

func openVNetTranslationDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)
	_, err := client.Translation.Delete(d.Id())

	return err
}
