package openvnet

import (
	"fmt"

	"github.com/axsh/openvnet/client/go-openvnet"
	"github.com/hashicorp/terraform/helper/schema"
)

func OpenVNetDnsService() *schema.Resource {
	return &schema.Resource{
		Create: openVNetDnsServiceCreate,
		Read:   openVNetDnsServiceRead,
		Delete: openVNetDnsServiceDelete,

		Schema: map[string]*schema.Schema{

			"uuid": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				Computed: true,
				ForceNew: true,
			},

			"network_services_uuid": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
			},

			"public_dns": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: true,
			},

			"dns_record": &schema.Schema{
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

						"name": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
							ForceNew: true,
						},

						"ipv4_address": &schema.Schema{
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

func openVNetDnsServiceCreate(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)
	params := &openvnet.DnsServicesCreateParams{
		UUID:               d.Get("uuid").(string),
		NetworkServiceUUID: d.Get("network_services_uuid").(string),
		PublicDns:          d.Get("public_dns").(string),
	}

	dnsService, _, err := client.DnsServices.Create(params)
	if err != nil {
		return err
	}

	if statics := d.Get("dns_record").([]interface{}); statics[:len(statics)-1] != nil {
		for _, static := range statics {
			params := static.(map[string]interface{})

			_, _, err := client.DnsServices.CreateRelation("dns_records", &openvnet.DnsRecordCreateParams{
				UUID:        params["uuid"].(string),
				Name:        params["name"].(string),
				Ipv4Address: params["ipv4_address"].(string),
			}, dnsService.UUID)

			if err != nil {
				return fmt.Errorf("faield to create static filter: %v", err)
			}
		}
	}

	d.SetId(dnsService.UUID)
	return openVNetDnsServiceRead(d, m)
}

func openVNetDnsServiceRead(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)
	dnsService, _, err := client.DnsServices.GetByUUID(d.Id())

	d.Set("public_dns", dnsService.PublicDns)
	d.Set("network_services_uuid", dnsService.NetworkServiceUUID)

	resp, _, err := client.DnsServices.GetRelations("dns_records", dnsService.UUID)
	if err != nil {
		return fmt.Errorf("failed to read list of statics: %v", err)
	}

	dnsRecordsList := resp.(*openvnet.DnsRecordList)
	dnsRecords := make([]map[string]interface{}, len(dnsRecordsList.Items))
	for i, dnsr := range dnsRecordsList.Items {
		dnsRecords[i] = make(map[string]interface{})
		dnsRecords[i]["name"] = dnsr.Name
		dnsRecords[i]["uuid"] = dnsr.UUID
		dnsRecords[i]["ipv4_address"] = dnsr.Ipv4Address
	}

	d.Set("dns_record", dnsRecords)
	return err
}

func openVNetDnsServiceDelete(d *schema.ResourceData, m interface{}) error {
	client := m.(*openvnet.Client)

	_, err := client.DnsServices.Delete(d.Id())

	return err
}
