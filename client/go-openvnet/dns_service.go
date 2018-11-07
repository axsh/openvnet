package openvnet

import "net/http"

const DnsServicesNamespace = "dns_services"

type DnsServices struct {
	ItemBase
	NetworkServiceID   int             `json:"network_service_id"`
	NetworkServiceUUID string          `json:"network_service_uuid"`
	PublicDns          string          `json:"public_dns,omitempty"`
	NetworkService     NetworkServices `json:"network_service"`
}

type DnsServicesList struct {
	ListBase
	Items []DnsServices `json:"items"`
}

type DnsServicesService struct {
	*BaseService
}

type DnsServicesCreateParams struct {
	UUID               string `url:"uuid,omitempty"`
	PublicDns          string `url:"public_dns,omitempty"`
	NetworkServiceUUID string `url:"network_service_uuid"`
}

func NewDnsServicesService(client *Client) *DnsServicesService {
	return &DnsServicesService{
		BaseService: &BaseService{
			client:       client,
			namespace:    DnsServicesNamespace,
			resource:     &DnsServices{},
			resourceList: &DnsServicesList{},
		},
	}
}

func (s *DnsServicesService) Create(params *DnsServicesCreateParams) (*DnsServices, *http.Response, error) {
	item, resp, err := s.BaseService.Create(params)
	return item.(*DnsServices), resp, err
}

func (s *DnsServicesService) Get() (*DnsServicesList, *http.Response, error) {
	item, resp, err := s.BaseService.Get()
	return item.(*DnsServicesList), resp, err
}

func (s *DnsServicesService) GetByUUID(id string) (*DnsServices, *http.Response, error) {
	item, resp, err := s.BaseService.GetByUUID(id)
	return item.(*DnsServices), resp, err
}

type DnsRecord struct {
	ItemBase
	DnsServiceId int    `json:"dns_service_id,omitempty"`
	Name         string `json:"name,omitempty"`
	Ipv4Address  int    `json:"ipv4_address,omitempty"`
	TTL          int    `json:"ttl,omitempty"`
}

type DnsRecordList struct {
	ListBase
	Items []DnsRecord `json:"items"`
}

type DnsRecordCreateParams struct {
	Name        string `url:"name"`
	UUID        string `url:"uuid"`
	Ipv4Address string `url:"ipv4_address"`
}

func (s *DnsServicesService) CreateDnsRecord(rel *Relation, params *DnsRecordCreateParams) (*DnsRecord, *http.Response, error) {
	dnsr := new(DnsRecord)
	resp, err := s.client.post(DnsServicesNamespace+"/"+rel.BaseID+"/"+rel.Type, &dnsr, params)
	return dnsr, resp, err
}

func (s *DnsServicesService) DeleteDnsRecord(params *Relation) (*http.Response, error) {
	return s.client.del(DnsServicesNamespace + "/" + params.BaseID + "/" + params.Type + "/" + params.RelationTypeUUID)
}

func (s *DnsServicesService) GetDnsRecords(uuid string) (*NetworkList, *http.Response, error) {
	list := new(NetworkList)
	resp, err := s.client.get(DnsServicesNamespace+"/"+uuid+"/dns_records", list)
	return list, resp, err
}
