package openvnet

import (
	"net/http"
)

const NetworkNamespace = "networks"

type Network struct {
	ItemBase
	DisplayName string `json:"display_name"`
	Ipv4Network string `json:"ipv4_network"`
	Ipv4Prefix  int    `json:"ipv4_prefix"`
	Mode        string `json:"mode"`
	DomainName  string `json:"domain_name"`
	SegmentID   int    `json:"segment_id"`
}

type NetworkList struct {
	ListBase
	Items []Network `json:"items"`
}

type NetworkService struct {
	*BaseService
}

type NetworkCreateParams struct {
	UUID        string `url:"uuid,omitempty"`
	DisplayName string `url:"display_name,omitempty"`
	Ipv4Network string `url:"ipv4_network"`
	Ipv4Prefix  int    `url:"ipv4_prefix,omitempty"`
	Mode        string `url:"mode"`
	DomainName  string `url:"domain_name,omitempty"`
	SegmentUUID string `url:"segment_id,omitempty"`
}

func NewNetworkService(client *Client) *NetworkService {
	return &NetworkService{
		BaseService: &BaseService{
			client:       client,
			namespace:    NetworkNamespace,
			resource:     &Network{},
			resourceList: &NetworkList{},
		},
	}
}

func (s *NetworkService) Create(params *NetworkCreateParams) (*Network, *http.Response, error) {
	item, resp, err := s.BaseService.Create(params)
	return item.(*Network), resp, err
}

func (s *NetworkService) Get() (*NetworkList, *http.Response, error) {
	item, resp, err := s.BaseService.Get()
	return item.(*NetworkList), resp, err
}

func (s *NetworkService) GetByUUID(id string) (*Network, *http.Response, error) {
	item, resp, err := s.BaseService.GetByUUID(id)
	return item.(*Network), resp, err
}
