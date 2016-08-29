package openvnet

import (
	"net/http"
)
type RouteLink struct {
	ID           int    `json:"id"`
	UUID         string `json:"uuid"`
	MacAddressID int    `json:"mac_address_id"`
	CreatedAt    string `json:"created_at"`
	DeletedAt    string `json:"deleted_at"`
	IsDeleted    bool   `json:"is_deleted"`
	MacAddress   string `json:"mac_address"`
}

type RouteLinkService struct {
	client *Client

	Namespace string
}

type RouteLinkCreateParams struct {
	UUID       string `url:"uuid"`
	MacAddress string `url:"mac_address"`
}

func (s *RouteLinkService) Create (params *RouteLinkCreateParams) (*RouteLink, *http.Response, error) {
	rl := new(RouteLink)
	ovnError := new(OpenVNetError)
	resp, err := s.client.sling.New().Post(s.Namespace).BodyForm(params).Receive(rl, ovnError)
	return rl, resp, err
}

func (s *RouteLinkService) Delete (id string) (*http.Response, error) {
	return nil, nil
}
