package openvnet

import (
	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

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

	createRelation := func(relationType string) {

		var extraParams interface{}
		if r := d.Get(relationType[:len(relationType)-1]); r != nil {
			for _, relationTypeMap := range r.([]interface{}) {
				relationMap := relationTypeMap.(map[string]interface{})

				params := &openvnet.TopologyRelation{
					Type:             relationType,
					TopologyUUID:     d.Id(),
					RelationTypeUUID: relationMap["uuid"].(string),
				}

				if relationType == "datapaths" {
					extraParams = &openvnet.TopologyDatapathParams{InterfaceUUID: relationMap["interface_uuid"].(string)}
				}

				client.Topology.CreateTopologyRelation(params, extraParams)
			}
		}
	}

	createRelation("networks")
	createRelation("route_links")
	createRelation("segments")
	createRelation("underlays")
	createRelation("datapaths")

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
	_, err := client.Topology.Delete(d.Id())

	deleteRelation := func(relationType string) {
		if r := d.Get(relationType[:len(relationType)-1]); r != nil {
			for _, relationTypeMap := range r.([]interface{}) {
				relationMap := relationTypeMap.(map[string]interface{})

				relation := &openvnet.TopologyRelation{
					TopologyUUID:     d.Id(),
					RelationTypeUUID: relationMap["uuid"].(string),
					Type:             relationType,
				}

				client.Topology.DeleteTopologyRelation(relation)
			}
		}
	}

	deleteRelation("networks")
	deleteRelation("route_links")
	deleteRelation("segments")
	deleteRelation("underlays")
	deleteRelation("datapaths")

	return err
}
