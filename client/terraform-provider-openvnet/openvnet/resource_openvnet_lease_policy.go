package openvnet

import (
	"fmt"

	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

var lpRelations = []string{
	"networks",
	"ip_lease_containers",
	"ip_retention_containers",
	"interfaces",
}

func OpenVNetLeasePolicy() *schema.Resource {
	return &schema.Resource{
		Create: openVNetLeasePolicyCreate,
		Read:   openVNetLeasePolicyRead, Delete: openVNetLeasePolicyDelete,

		Schema: map[string]*schema.Schema{

			"uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"mode": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"timing": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
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

			"interface": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"uuid": &schema.Schema{
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

func openVNetLeasePolicyCreate(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)

	params := &openvnet.LeasePolicyCreateParams{
		UUID:   d.Get("uuid").(string),
		Timing: d.Get("timing").(string),
	}

	leasePolicy, _, err := client.LeasePolicy.Create(params)
	if err != nil {
		return fmt.Errorf("failed to crate lease policy: %v", err)
	}
	d.SetId(leasePolicy.UUID)

	for _, relation := range lpRelations {
		_, err := parseRelation(d, relation, func(p map[string]interface{}) (interface{}, error) {
			var ep interface{}
			if relation == "networks" {
				ep = &openvnet.LeasePolicyRelationCreateParams{p["ip_range_group_uuid"].(string)}
			}
			r, _, e := client.LeasePolicy.CreateRelation(relation, ep, d.Id(), p["uuid"].(string))
			return r, e
		})

		if err != nil {
			return fmt.Errorf("failed to create relation %s: %v", relation, err)
		}
	}

	return openVNetLeasePolicyRead(d, m)
}

func openVNetLeasePolicyRead(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)
	leasePolicy, _, err := client.LeasePolicy.GetByUUID(d.Id())

	if err != nil {
		return err
	}

	d.Set("timing", leasePolicy.Timing)
	d.Set("mode", leasePolicy.Mode)

	return nil
}

func openVNetLeasePolicyDelete(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	for _, relation := range lpRelations {
		_, err := parseRelation(d, relation, func(p map[string]interface{}) (interface{}, error) {

			_, err := client.LeasePolicy.DeleteRelation(relation, d.Id(), p["uuid"].(string))
			return nil, err
		})

		if err != nil {
			return fmt.Errorf("failed to create relation %s: %v", relation, err)
		}
	}

	_, err := client.LeasePolicy.Delete(d.Id())

	return err
}
