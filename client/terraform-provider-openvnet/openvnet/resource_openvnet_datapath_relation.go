package openvnet

import (
	"fmt"

	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

var dpRelations = []string{
	"networks",
	"route_links",
	"segments",
}

func OpenVNetDatapathRelation() *schema.Resource {
	return &schema.Resource{
		Create: openVNetDatapathRelationCreate,
		Read:   openVNetDatapathRelationRead,
		Delete: openVNetDatapathRelationDelete,

		Schema: map[string]*schema.Schema{

			"uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"network": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"uuid": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
							ForceNew: true,
						},

						"mac_address": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							ForceNew: true,
						},

						"interface_uuid": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							ForceNew: true,
						},
					},
				},
			},

			"route_link": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"uuid": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
							ForceNew: true,
						},

						"mac_address": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							ForceNew: true,
						},

						"interface_uuid": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							ForceNew: true,
						},
					},
				},
			},

			"segment": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"uuid": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
							ForceNew: true,
						},

						"mac_address": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							ForceNew: true,
						},

						"interface_uuid": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							ForceNew: true,
						},
					},
				},
			},
		},
	}
}

func openVNetDatapathRelationCreate(d *schema.ResourceData, m interface{}) error {

	d.SetId(d.Get("uuid").(string))
	client := m.(*openvnet.Client)

	for _, relation := range dpRelations {
		_, err := parseRelation(d, relation, func(p map[string]interface{}) (interface{}, error) {
			r, _, e := client.Datapath.CreateRelation(relation, &openvnet.DatapathRelationCreateParams{
				InterfaceUUID: p["interface_uuid"].(string),
				MacAddress:    p["mac_address"].(string),
			}, d.Id(), p["uuid"].(string))
			return r, e
		})

		if err != nil {
			return fmt.Errorf("failed to create relation %s: %v", relation, err)
		}
	}

	return nil
}

func openVNetDatapathRelationRead(d *schema.ResourceData, m interface{}) error {
	return nil
}

func openVNetDatapathRelationDelete(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	for _, relation := range dpRelations {
		_, err := parseRelation(d, relation, func(p map[string]interface{}) (interface{}, error) {
			_, err := client.Datapath.DeleteRelation(relation, d.Id(), p["uuid"].(string))
			return nil, err
		})

		if err != nil {
			return fmt.Errorf("failed to create relation %s: %v", relation, err)
		}
	}

	return nil
}
