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
	client *Client
}

type FilterCreateParams struct {
	UUID               string `url:"mode"`
	InterfaceUUID      string `url:"interface_uuid"`
	Mode               string `url:"mode"`
	EgressPassthrough  bool   `url:"egress_passthrough,omitempty"`
	IngressPassthrough bool   `url:"ingress_passthrough,omitempty"`
}

func (s *FilterService) Create(params *FilterCreateParams) (*Filter, *http.Response, error) {
	fil := new(Filter)
	resp, err := s.client.post(FilterNamespace, fil, params)
	return fil, resp, err
}

func (s *FilterService) Delete(id string) (*http.Response, error) {
	return s.client.del(FilterNamespace + "/" + id)
}

func (s *FilterService) Get() (*FilterList, *http.Response, error) {
	list := new(FilterList)
	resp, err := s.client.get(FilterNamespace, list)
	return list, resp, err
}

func (s *FilterService) GetByUUID(id string) (*Filter, *http.Response, error) {
	i := new(Filter)
	resp, err := s.client.get(FilterNamespace+"/"+id, i)
	return i, resp, err
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
	SrcPort    string `url:"src_port,omitempty"`
	DstPort    string `url:"dst_port,omitempty"`
	Action     string `url:"action,omitempty"`
}

func (s *FilterService) CreateStatic(uuid string, params *FilterStaticCreateParams) (*FilterStatic, *http.Response, error) {
	st := new(FilterStatic)
	resp, err := s.client.post(FilterNamespace+"/"+uuid+"/static", st, params)
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
