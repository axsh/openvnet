package openvnet

import (
	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetDatapathRelation() *schema.Resource {
	return &schema.Resource{
		Create: openVNetDatapathRelationCreate,
		Read:   openVNetDatapathRelationRead,
		Update: openVNetDatapathRelationUpdate,
		Delete: openVNetDatapathRelationDelete,

		Schema: map[string]*schema.Schema{

			"uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
			},

			"network": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"uuid": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
						},

						"mac_address": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
						},

						"interface_uuid": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
						},
					},
				},
			},

			"route_link": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"uuid": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
						},

						"mac_address": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
						},

						"interface_uuid": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
						},
					},
				},
			},

			"segment": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"uuid": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
						},

						"mac_address": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
						},

						"interface_uuid": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
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

	createRelation := func(relationType string) {
		if r := d.Get(relationType[:len(relationType)-1]); r != nil {
			for _, relationTypeMap := range r.([]interface{}) {
				relationMap := relationTypeMap.(map[string]interface{})

				relation := &openvnet.Relation{
					DatapathID:       d.Id(),
					Type:             relationType,
					RelationTypeUUID: relationMap["uuid"].(string),
				}

				relationParams := &openvnet.DatapathRelationCreateParams{
					InterfaceUUID: relationMap["interface_uuid"].(string),
					MacAddress:    relationMap["mac_address"].(string),
				}

				client.Datapath.CreateDatapathRelation(relation, relationParams)
			}
		}
	}

	createRelation("networks")
	createRelation("route_links")
	createRelation("segments")

	return nil
}

func openVNetDatapathRelationRead(d *schema.ResourceData, m interface{}) error {
	return nil
}

func openVNetDatapathRelationUpdate(d *schema.ResourceData, m interface{}) error {
	return nil
}

func openVNetDatapathRelationDelete(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	deleteRelation := func(relationType string) {
		if r := d.Get(relationType[:len(relationType)-1]); r != nil {
			for _, relationTypeMap := range r.([]interface{}) {
				relationMap := relationTypeMap.(map[string]interface{})

				relation := &openvnet.Relation{
					DatapathID:       d.Id(),
					Type:             relationType,
					RelationTypeUUID: relationMap["uuid"].(string),
				}

				client.Datapath.DeleteDatapathRelation(relation)
			}
		}
	}

	deleteRelation("networks")
	deleteRelation("route_links")
	deleteRelation("segments")

	return nil
}
