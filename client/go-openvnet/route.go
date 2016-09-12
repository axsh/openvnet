package openvnet

import (
	"net/http"
)

const RouteNamespace = "routes"

type Route struct {
	ItemBase
	RouteLinkUUID string `json:"route_link_uuid"`
	NetworkUUID   string `json:"network_uuid"`
	InterfaceUUID string `json:"interface_uuid"`
	Mode          string `json:"mode"`
	Ipv4Network   string `json:"ipv4_network"`
	Ipv4Prefix    int    `json:"ipv4_prefix"`
	Ingress       bool   `json:"ingress"`
	Egress        bool   `json:"egress"`
}

type RouteList struct {
	ListBase
	Items []Route
}

type RouteService struct {
	client *Client
}

type RouteCreateParams struct {
	UUID          string `url:"uuid,omitempty"`
	InterfaceUUID string `url:"interface_uuid,omitempty"`
	RouteLinkUUID string `url:"route_link_uuid"`
	NetworkUUID   string `url:"network_uuid"`
	Ipv4Network   string `url:"ipv4_network,omitempty"`
	Ipv4Prefix    ing    `url:"ipv4_prefix,omitempty"`
	Ingress       bool   `url:"ingress,omitempty"`
	Egress        bool   `url:"egress,omitempty"`
}

func (s *RouteService) Create(params *RouteCreateParams) (*Route, *http.Response, error) {
	r := new(Route)
	resp, err := s.client.post(RouteNamespace, r, params)
	return r, resp, err

}

func (s *RouteService) Delete(id string) (*http.Response, error) {
	return s.client.del(id)
}
