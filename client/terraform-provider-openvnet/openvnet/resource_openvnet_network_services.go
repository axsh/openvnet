package openvnet

import (
	"fmt"

	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetNetworkServices() *schema.Resource {
	return &schema.Resource{
		Create: openVNetNetworkServicesCreate,
		Read:   openVNetNetworkServicesRead,
		Delete: openVNetNetworkServicesDelete,

		Schema: map[string]*schema.Schema{

			"uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"display_name": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"interface_uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"incoming_port": &schema.Schema{
				Type:     schema.TypeInt,
				Optional: true,
				ForceNew: true,
			},

			"outgoing_port": &schema.Schema{
				Type:     schema.TypeInt,
				Optional: true,
				ForceNew: true,
			},

			"type": &schema.Schema{
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

func openVNetNetworkServicesCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	params := &openvnet.NetworkServicesCreateParams{
		UUID:          d.Get("uuid").(string),
		InterfaceUUID: d.Get("interface_uuid").(string),
		DisplayName:   d.Get("display_name").(string),
		IncomingPort:  d.Get("incoming_port").(int),
		OutgoingPort:  d.Get("outgoing_port").(int),
		Type:          d.Get("type").(string),
		Mode:          d.Get("mode").(string),
	}

	networkServices, _, err := client.NetworkServices.Create(params)
	if err != nil {
		return fmt.Errorf("failed to create network services: %v", err)
	}
	d.SetId(networkServices.UUID)

	return openVNetNetworkServicesRead(d, m)
}

func openVNetNetworkServicesRead(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)
	networkServices, _, err := client.NetworkServices.GetByUUID(d.Id())

	d.Set("display_name", networkServices.DisplayName)
	d.Set("incoming_port", networkServices.IncomingPort)
	d.Set("outgoing_port", networkServices.OutgoingPort)
	d.Set("mode", networkServices.Mode)

	return err
}

func openVNetNetworkServicesDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)
	_, err := client.NetworkServices.Delete(d.Id())

	return err
}
