package openvnet

import (
	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetSecurityGroup() *schema.Resource {
	return &schema.Resource{
		Create: openVNetSecurityGroupCreate,
		Read:   openVNetSecurityGroupRead,
		Update: openVNetSecurityGroupUpdate,
		Delete: openVNetSecurityGroupDelete,

		Schema: map[string]*schema.Schema{

			"uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
			},

			"display_name": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
			},

			"description": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
			},
		},
	}
}

func openVNetSecurityGroupCreate(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)

	params := &openvnet.SecurityGroupCreateParams{
		UUID:        d.Get("uuid").(string),
		DisplayName: d.Get("display_name").(string),
		Description: d.Get("description").(string),
	}

	sgroup, _, err := client.SecurityGroup.Create(params)
	d.SetId(sgroup.UUID)

	if err != nil {
		return err
	}

	return nil
}

func openVNetSecurityGroupRead(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)
	sgroup, _, err := client.SecurityGroup.GetByUUID(d.Id())

	if err != nil {
		return err
	}

	d.Set("display_name", sgroup.DisplayName)
	d.Set("description", sgroup.Description)

	return nil
}

func openVNetSecurityGroupUpdate(d *schema.ResourceData, m interface{}) error {
	return nil
}

func openVNetSecurityGroupDelete(d *schema.ResourceData, m interface{}) error {

	client := m.(*openvnet.Client)
	_, err := client.SecurityGroup.Delete(d.Id())

	return err
}
