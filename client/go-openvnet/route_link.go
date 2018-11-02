package openvnet

import (
	"net/http"
)

const RouteLinkNamespace = "route_links"

type RouteLink struct {
	ItemBase
	MacAddressID int    `json:"mac_address_id"`
	MacAddress   string `json:"mac_address"`
}

type RouteLinkList struct {
	ListBase
	Items []RouteLink
}

type RouteLinkService struct {
	*BaseService
}

type RouteLinkCreateParams struct {
	UUID       string `url:"uuid,omitempty"`
	MacAddress string `url:"mac_address,omitempty"`
}

func NewRouteLinkService(client *Client) *RouteLinkService {
	return &RouteLinkService{
		BaseService: &BaseService{
			client:       client,
			namespace:    RouteLinkNamespace,
			resource:     &RouteLink{},
			resourceList: &RouteLinkList{},
		},
	}
}

func (s *RouteLinkService) Create(params *RouteLinkCreateParams) (*RouteLink, *http.Response, error) {
	item, resp, err := s.BaseService.Create(params)
	return item.(*RouteLink), resp, err
}

func (s *RouteLinkService) Get() (*RouteLinkList, *http.Response, error) {
	item, resp, err := s.BaseService.Get()
	return item.(*RouteLinkList), resp, err
}

func (s *RouteLinkService) GetByUUID(id string) (*RouteLink, *http.Response, error) {
	item, resp, err := s.BaseService.GetByUUID(id)
	return item.(*RouteLink), resp, err
}
