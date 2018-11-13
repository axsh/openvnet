package openvnet

import (
	"net/http"
)

const NetworkServicesNamespace = "network_services"

type NetworkServices struct {
	ItemBase
	DisplayName  string `json:"display_name,omitempty"`
	InterfaecID  string `json:"interface_id,omitempty"`
	IncomingPort int    `json:"incoming_port,omitempty"`
	OutgoingPort int    `json:"outgoing_port,omitempty"`
	Type         string `json:"type,omitempty"`
	Mode         string `json:"mode"`
}

type NetworkServicesList struct {
	ListBase
	Items []NetworkServices `json:"items"`
}

type NetworkServicesService struct {
	*BaseService
}

type NetworkServicesCreateParams struct {
	UUID          string `url:"uuid,omitempty"`
	DisplayName   string `url:"display_name,omitempty"`
	InterfaceUUID string `url:"interface_uuid,omitempty"`
	IncomingPort  int    `url:"incoming_port,omitempty"`
	OutgoingPort  int    `url:"outgoing_port,omitempty"`
	Type          string `url:"type,omitempty"`
	Mode          string `url:"mode"`
}

func NewNetworkServicesService(client *Client) *NetworkServicesService {
	return &NetworkServicesService{
		BaseService: &BaseService{
			client:       client,
			namespace:    NetworkServicesNamespace,
			resource:     &NetworkServices{},
			resourceList: &NetworkServicesList{},
		},
	}
}

func (s *NetworkServicesService) Create(params *NetworkServicesCreateParams) (*NetworkServices, *http.Response, error) {
	item, resp, err := s.BaseService.Create(params)
	return item.(*NetworkServices), resp, err
}

func (s *NetworkServicesService) Get() (*NetworkServicesList, *http.Response, error) {
	item, resp, err := s.BaseService.Get()
	return item.(*NetworkServicesList), resp, err
}

func (s *NetworkServicesService) GetByUUID(id string) (*NetworkServices, *http.Response, error) {
	item, resp, err := s.BaseService.GetByUUID(id)
	return item.(*NetworkServices), resp, err
}
