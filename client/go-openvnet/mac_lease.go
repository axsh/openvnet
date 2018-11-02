package openvnet

import (
	"net/http"
)

const MacLeaseNamespace = "mac_leases"

type MacLease struct {
	ItemBase
	InterfaceID   int       `json:"interface_id"`
	MacAddressID  int       `json:"mac_address_id"`
	MacAddress    string    `json:"mac_address"`
	SegmentID     int       `json:"segment_id"`
	IpLeases      []IpLease `json:"ip_leases"`
	InterfaceUUID string    `json:"interface_uuid"`
}

type MacLeaseList struct {
	ListBase
	Items []MacLease `json:"items"`
}

type MacLeaseService struct {
	*BaseService
}

type MacLeaseCreateParams struct {
	UUID          string `url:"uuid,omitempty"`
	InterfaceUUID string `url:"interface_uuid"`
	MacAddress    string `url:"mac_address"`
	SegmentUUID   string `url:"segment_uuid,omitempty"`
}

func NewMacLeaseService(client *Client) *MacLeaseService {
	return &MacLeaseService{
		BaseService: &BaseService{
			client:       client,
			namespace:    MacLeaseNamespace,
			resource:     &MacLease{},
			resourceList: &MacLeaseList{},
		},
	}
}

func (s *MacLeaseService) Create(params *MacLeaseCreateParams) (*MacLease, *http.Response, error) {
	item, resp, err := s.BaseService.Create(params)
	return item.(*MacLease), resp, err
}

func (s *MacLeaseService) Get() (*MacLeaseList, *http.Response, error) {
	item, resp, err := s.BaseService.Get()
	return item.(*MacLeaseList), resp, err
}

func (s *MacLeaseService) GetByUUID(id string) (*MacLease, *http.Response, error) {
	item, resp, err := s.BaseService.GetByUUID(id)
	return item.(*MacLease), resp, err
}
