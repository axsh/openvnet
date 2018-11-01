package openvnet

import (
	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetLeasePolicyRelation() *schema.Resource {
	return &schema.Resource{
		Create: openVNetLeasePolicyRelationCreate,
		Read:   openVNetLeasePolicyRelationRead,
		Delete: openVNetLeasePolicyRelationDelete,

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

						"ip_range_group_uuid": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
							ForceNew: true,
						},
					},
				},
			},

			"ip_lease_container": &schema.Schema{
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
					},
				},
			},

			"ip_retention_container": &schema.Schema{
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
					},
				},
			},

			"interface": &schema.Schema{
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
					},
				},
			},
		},
	}
}

func openVNetLeasePolicyRelationCreate(d *schema.ResourceData, m interface{}) error {

	d.SetId(d.Get("uuid").(string))
	client := m.(*openvnet.Client)

	createRelation := func(relationType string) {
		if r := d.Get(relationType[:len(relationType)-1]); r != nil {
			for _, relationTypeMap := range r.([]interface{}) {
				relationMap := relationTypeMap.(map[string]interface{})

				relation := &openvnet.Relation{
					LeasePolicyID:    d.Id(),
					Type:             relationType,
					RelationTypeUUID: relationMap["uuid"].(string),
				}

				if relation.Type == "networks" {
					relationParams := &openvnet.LeasePolicyRelationCreateParams{
						IpRangeGroupUUID: relationMap["ip_range_group_uuid"].(string),
					}
				}

				client.LeasePolicy.CreateLeasePolicyRelation(relation, relationParams)
			}
		}
	}

	createRelation("networks")
	createRelation("ip_lease_containers")
	createRelation("ip_retention_containers")
	createRelation("interfaces")

	return nil
}

func openVNetLeasePolicyRelationRead(d *schema.ResourceData, m interface{}) error {
	return nil
}

func openVNetLeasePolicyRelationDelete(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	deleteRelation := func(relationType string) {
		if r := d.Get(relationType[:len(relationType)-1]); r != nil {
			for _, relationTypeMap := range r.([]interface{}) {
				relationMap := relationTypeMap.(map[string]interface{})

				relation := &openvnet.Relation{
					LeasePolicyID:    d.Id(),
					Type:             relationType,
					RelationTypeUUID: relationMap["uuid"].(string),
				}

				client.LeasePolicy.DeleteLeasePolicyRelation(relation)
			}
		}
	}

	deleteRelation("networks")
	deleteRelation("ip_lease_containers")
	deleteRelation("ip_retention_containers")
	deleteRelation("interfaces")

	return nil
}
