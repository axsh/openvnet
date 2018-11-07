package openvnet

import "net/http"

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
	return &TranslationService{
		BaseService: &BaseService{
			client:       client,
			namespace:    "translations",
			resource:     &Translation{},
			resourceList: &TranslationList{},
		},
	}
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
	InressPortNumber   string `json:"ingress_port_number,omitempty"`
	EgressPortNumber   string `json:"egress_port_number,omitempty"`
}

type TranslationStaticAddressList struct {
	ListBase
	Items []TranslationStaticAddress `json:"items"`
}

type TranslationStaticParams struct {
	TranslationUUID    int    `url:"translation_id,omitempty"`
	RouteLinkUUID      int    `url:"route_link_id,omitempty"`
	IngressIpv4Address string `url:"ingress_ipv4_address"`
	EgressIpv4Address  string `url:"egress_ipv4_address"`
	InressPortNumber   string `url:"ingress_port_number,omitempty"`
	EgressPortNumber   string `url:"egress_port_number,omitempty"`
	InressNetworkUUID  int    `url:"ingress_network,omitempty"`
	EgressNetworkUUID  int    `url:"egress_network,omitempty"`
}

func (s *TranslationService) CreateStatic(uuid string, params *TranslationStaticParams) (*TranslationStaticAddress, *http.Response, error) {
	st := new(TranslationStaticAddress)
	resp, err := s.client.post(FilterNamespace+"/"+uuid+"/static_address", st, params)
	return st, resp, err
}

func (s *TranslationService) DeleteStatic(uuid string, param *TranslationStaticParams) (*http.Response, error) {
	ovnError := new(OpenVNetError)
	resp, err := s.client.sling.New().Delete(FilterNamespace+"/"+uuid+"/static_address").BodyForm(param).Receive(nil, ovnError)
	return checkError(ovnError, resp, err)
}

func (s *TranslationService) GetStatic(uuid string) (*TranslationStaticAddressList, *http.Response, error) {
	list := new(TranslationStaticAddressList)
	resp, err := s.client.get(FilterNamespace+"/"+uuid+"/static_address", list)
	return list, resp, err
}
