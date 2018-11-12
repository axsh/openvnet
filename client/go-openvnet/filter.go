package openvnet

import "net/http"

const FilterNamespace = "filters"

type Filter struct {
	ItemBase
	Mode               string `json:"mode,omitempty"`
	EgressPassthrough  bool   `json:"egress_passthrough,omitempty"`
	IngressPassthrough bool   `json:"ingress_passthrough,omitempty"`
}

type FilterList struct {
	ListBase
	Item []Filter `json:"items"`
}

type FilterService struct {
	*BaseService
}

type FilterCreateParams struct {
	UUID               string `url:"uuid"`
	InterfaceUUID      string `url:"interface_uuid"`
	Mode               string `url:"mode"`
	EgressPassthrough  bool   `url:"egress_passthrough,omitempty"`
	IngressPassthrough bool   `url:"ingress_passthrough,omitempty"`
}

func NewFilterService(client *Client) *FilterService {
	return &FilterService{
		BaseService: &BaseService{
			client:       client,
			namespace:    FilterNamespace,
			resource:     &Filter{},
			resourceList: &FilterList{},
		},
	}
}

func (s *FilterService) Create(params *FilterCreateParams) (*Filter, *http.Response, error) {
	item, resp, err := s.BaseService.Create(params)
	return item.(*Filter), resp, err
}

func (s *FilterService) Get() (*FilterList, *http.Response, error) {
	item, resp, err := s.BaseService.Get()
	return item.(*FilterList), resp, err
}

func (s *FilterService) GetByUUID(id string) (*Filter, *http.Response, error) {
	item, resp, err := s.BaseService.GetByUUID(id)
	return item.(*Filter), resp, err
}

type FilterStatic struct {
	FilterID   int    `json:"filter_id,omitempty"`
	Protocol   string `json:"protocol,omitempty"`
	Action     string `json:"action,omitempty"`
	SrcAddress string `json:"src_address,omitempty"`
	DstAddress string `json:"dst_address,omitempty"`
	SrcPrefix  int    `json:"src_prefix,omitempty"`
	DstPrefix  int    `json:"dst_prefix,omitempty"`
	SrcPort    int    `json:"src_port,omitempty"`
	DstPort    int    `json:"dst_port,omitempty"`
}

type FilterStaticList struct {
	ListBase
	Items []FilterStatic `json:"items"`
}

type FilterStaticCreateParams struct {
	Protocol   string `url:"protocol"`
	SrcAddress string `url:"src_address,omitempty"`
	DstAddress string `url:"dst_address,omitempty"`
	SrcPort    int    `url:"src_port,omitempty"`
	DstPort    int    `url:"dst_port,omitempty"`
	Action     string `url:"action,omitempty"`
}

func (s *FilterService) CreateStatic(uuid string, params *FilterStaticCreateParams) (*FilterStatic, *http.Response, error) {
	st := new(FilterStatic)
	resp, err := s.client.post(FilterNamespace+"/"+uuid+"/static", &st, params)
	return st, resp, err
}

func (s *FilterService) DeleteStatic(uuid string, param *FilterStaticCreateParams) (*http.Response, error) {
	ovnError := new(OpenVNetError)
	resp, err := s.client.sling.New().Delete(FilterNamespace+"/"+uuid+"/static").BodyForm(param).Receive(nil, ovnError)
	return checkError(ovnError, resp, err)
}

func (s *FilterService) GetStatic(uuid string) (*FilterStaticList, *http.Response, error) {
	list := new(FilterStaticList)
	resp, err := s.client.get(FilterNamespace+"/"+uuid+"/static", list)
	return list, resp, err
}
