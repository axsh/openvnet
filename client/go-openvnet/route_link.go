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
	client *Client
}

type RouteLinkCreateParams struct {
	UUID       string `url:"uuid,omitempty"`
	MacAddress string `url:"mac_address"`
}

func (s *RouteLinkService) Create(params *RouteLinkCreateParams) (*RouteLink, *http.Response, error) {
	rl := new(RouteLink)
	resp, err := s.client.post(RouteLinkNamespace, rl, params)
	return rl, resp, err
}

func (s *RouteLinkService) Delete(id string) (*http.Response, error) {
	return s.client.del(RouteLinkNamespace + "/" + id)
}

func (s *RouteLinkService) Get() (*RouteLinkList, *http.Response, error) {
	list := new(RouteLinkList)
	resp, err := s.client.get(RouteLinkNamespace, list)
	return list, resp, err
}

func (s *RouteLinkService) GetByUUID(id string) (*RouteLink, *http.Response, error) {
	rl := new(RouteLink)
	resp, err := s.client.get(RouteLinkNamespace+"/"+id, rl)
	return rl, resp, err
}
