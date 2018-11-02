package openvnet

import "net/http"

const IpRetentionContainerNamespace = "ip_retention_containers"

type IpRetentionContainer struct {
	ItemBase
	LeaseTime int `json:"lease_time,omitempty"`
	GraceTime int `json:"grace_time,omitempty"`
}

type IpRetentionContainerList struct {
	ListBase
	Items []IpRetentionContainer `json:"items"`
}

type IpRetentionContainerService struct {
	*BaseService
}

type IpRetentionContainerCreateParams struct {
	UUID      string `url:"uuid"`
	LeaseTime int    `url:"lease_time,omitempty"`
	GraceTime int    `url:"grace_time,omitempty"`
}

func NewIpRetentionContainerService(client *Client) *IpRetentionContainerService {
	return &IpRetentionContainerService{
		BaseService: &BaseService{
			client:       client,
			namespace:    IpRetentionContainerNamespace,
			resource:     &IpRetentionContainer{},
			resourceList: &IpRetentionContainerList{},
		},
	}
}

func (s *IpRetentionContainerService) Create(params *IpRetentionContainerCreateParams) (*IpRetentionContainer, *http.Response, error) {
	item, resp, err := s.BaseService.Create(params)
	return item.(*IpRetentionContainer), resp, err
}

func (s *IpRetentionContainerService) Get() (*IpRetentionContainerList, *http.Response, error) {
	item, resp, err := s.BaseService.Get()
	return item.(*IpRetentionContainerList), resp, err
}

func (s *IpRetentionContainerService) GetByUUID(id string) (*IpRetentionContainer, *http.Response, error) {
	item, resp, err := s.BaseService.GetByUUID(id)
	return item.(*IpRetentionContainer), resp, err
}
