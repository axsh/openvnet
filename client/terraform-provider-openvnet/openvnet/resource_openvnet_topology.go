package openvnet

import (
	"fmt"

	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

var topoRelations = []string{
	"underlays",
	"segments",
	"networks",
	"route_links",
	"datapaths",
}

func OpenVNetTopology() *schema.Resource {
	return &schema.Resource{
		Create: openVNetTopologyCreate,
		Read:   openVNetTopologyRead,
		Delete: openVNetTopologyDelete,

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

			"network": &schema.Schema{
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
					},
				},
			},

			"underlay": &schema.Schema{
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

			"datapath": &schema.Schema{
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
						"interface_uuid": &schema.Schema{
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

func openVNetTopologyCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	params := &openvnet.TopologyCreateParams{
		UUID: d.Get("uuid").(string),
		Mode: d.Get("mode").(string),
	}

	tp, _, _ := client.Topology.Create(params)
	d.SetId(tp.UUID)

	for _, relation := range topoRelations {
		_, err := parseRelation(d, relation, func(p map[string]interface{}) (interface{}, error) {
			var ep interface{}
			if relation == "datapaths" {
				ep = &openvnet.TopologyDatapathParams{InterfaceUUID: p["interface_uuid"].(string)}
			}
			r, _, e := client.Topology.CreateRelation(relation, ep, d.Id(), p["uuid"].(string))
			return r, e
		})

		if err != nil {
			return fmt.Errorf("failed to create relation %s: %v", relation, err)
		}
	}

	return openVNetTopologyRead(d, m)
}

func openVNetTopologyRead(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)
	tp, _, err := client.Topology.GetByUUID(d.Id())

	if err != nil {
		return err
	}

	d.Set("mode", tp.Mode)

	return nil
}

func openVNetTopologyDelete(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	for _, relation := range topoRelations {
		_, err := parseRelation(d, relation, func(p map[string]interface{}) (interface{}, error) {

			_, err := client.Topology.DeleteRelation(relation, d.Id(), p["uuid"].(string))
			return nil, err
		})

		if err != nil {
			return fmt.Errorf("failed to create relation %s: %v", relation, err)
		}
	}

	_, err := client.Topology.Delete(d.Id())

	return err
}
