package openvnet

import "net/http"

const IpLeaseContainerNamespace = "ip_lease_containers"

type IpLeaseContainer struct {
	ItemBase
}

type IpLeaseContainerList struct {
	ListBase
	Items []IpLeaseContainer `json:"items"`
}

type IpLeaseContainerService struct {
	*BaseService
}

type IpLeaseContainerCreateParams struct {
	UUID string `url:"uuid,omitempty"`
}

func NewIpLeaseContainerService(client *Client) *IpLeaseContainerService {
	return &IpLeaseContainerService{
		BaseService: &BaseService{
			client:       client,
			namespace:    IpLeaseContainerNamespace,
			resource:     &IpLeaseContainer{},
			resourceList: &IpLeaseContainerList{},
		},
	}
}

func (s *IpLeaseContainerService) Create(params *IpLeaseContainerCreateParams) (*IpLeaseContainer, *http.Response, error) {
	item, resp, err := s.BaseService.Create(params)
	return item.(*IpLeaseContainer), resp, err
}

func (s *IpLeaseContainerService) Get() (*IpLeaseContainerList, *http.Response, error) {
	item, resp, err := s.BaseService.Get()
	return item.(*IpLeaseContainerList), resp, err
}

func (s *IpLeaseContainerService) GetByUUID(id string) (*IpLeaseContainer, *http.Response, error) {
	item, resp, err := s.BaseService.GetByUUID(id)
	return item.(*IpLeaseContainer), resp, err
}
