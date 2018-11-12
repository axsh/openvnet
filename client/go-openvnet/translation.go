package openvnet

import (
	"fmt"
	"net/http"
)

type Translation struct {
	ItemBase
	Mode        string `json:"mode"`
	InterfaceID int    `json:"interface_id"`
	Passthrough bool   `json:"passthrough"`
}

type TranslationList struct {
	ListBase
	Items []Translation
}

type TranslationService struct {
	*BaseService
}

type TranslationCreateParams struct {
	UUID          string `url:"uuid,omitempty"`
	InterfaceUUID string `url:"interface_uuid"`
	Mode          string `url:"mode"`
	Passthrough   bool   `url:"passthrough,omitempty"`
}

func NewTranslationService(client *Client) *TranslationService {
	s := &TranslationService{
		BaseService: &BaseService{
			client:           client,
			namespace:        "translations",
			resource:         &Translation{},
			resourceList:     &TranslationList{},
			relationServices: make(map[string]*RelationService),
		},
	}
	s.NewRelationService(&TranslationStaticAddress{}, &TranslationStaticAddressList{}, "static_address")
	return s
}

func (s *TranslationService) Create(params *TranslationCreateParams) (*Translation, *http.Response, error) {
	item, resp, err := s.BaseService.Create(params)
	return item.(*Translation), resp, err
}

func (s *TranslationService) Get() (*TranslationList, *http.Response, error) {
	item, resp, err := s.BaseService.Get()
	return item.(*TranslationList), resp, err
}

func (s *TranslationService) GetByUUID(uuid string) (*Translation, *http.Response, error) {
	item, resp, err := s.BaseService.GetByUUID(uuid)
	return item.(*Translation), resp, err
}

type TranslationStaticAddress struct {
	ItemBase
	ID                 int    `json:"id,omitempty"`
	TranslationID      int    `json:"translation_id,omitempty"`
	RouteLinkID        int    `json:"route_link_id,omitempty"`
	IngressIpv4Address string `json:"ingress_ipv4_address,omitempty"`
	EgressIpv4Address  string `json:"egress_ipv4_address,omitempty"`
	IngressPortNumber  string `json:"ingress_port_number,omitempty"`
	EgressPortNumber   string `json:"egress_port_number,omitempty"`
}

type TranslationStaticAddressList struct {
	ListBase
	Items []TranslationStaticAddress `json:"items"`
}

type TranslationStaticCreateParams struct {
	TranslationUUID    string `url:"translation_id,omitempty"`
	RouteLinkUUID      string `url:"route_link_id,omitempty"`
	IngressIpv4Address string `url:"ingress_ipv4_address"`
	EgressIpv4Address  string `url:"egress_ipv4_address"`
	IngressPortNumber  int    `url:"ingress_port_number,omitempty"`
	EgressPortNumber   int    `url:"egress_port_number,omitempty"`
	IngressNetworkUUID string `url:"ingress_network,omitempty"`
	EgressNetworkUUID  string `url:"egress_network,omitempty"`
}

func (s *TranslationService) DeleteRelation(uuid string, param *TranslationStaticCreateParams) (*http.Response, error) {
	ovnError := new(OpenVNetError)
	resp, err := s.client.sling.New().Delete(FilterNamespace+"/"+uuid+"/static_address").BodyForm(param).Receive(nil, ovnError)
	return checkError(ovnError, resp, err)
}

func (s *TranslationService) GetRelations(uuid string) (*TranslationStaticAddressList, *http.Response, error) {
	return nil, nil, fmt.Errorf("not implemented in vnet api")
}
