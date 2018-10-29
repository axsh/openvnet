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
	IPLeases      []IpLease `json:"ip_leases"`
	InterfaceUUID string    `json:"interface_uuid"`
}

type MacLeaseList struct {
	ListBase
	Items []MacLease `json:"items"`
}

type MacLeaseService struct {
	client *Client
}

type MacLeaseCreateParams struct {
	UUID          string `url:"uuid,omitempty"`
	InterfaceUUID string `url:"interface_uuid"`
	MacAddress    string `url:"mac_address"`
	SegmentUUID   string `url:"segment_uuid,omitempty"`
}

func (s *MacLeaseService) Create(params *MacLeaseCreateParams) (*MacLease, *http.Response, error) {
	ml := new(MacLease)
	resp, err := s.client.post(MacLeaseNamespace, ml, params)
	return ml, resp, err
}

func (s *MacLeaseService) Delete(id string) (*http.Response, error) {
	return s.client.del(MacLeaseNamespace + "/" + id)
}

func (s *MacLeaseService) Get() (*MacLeaseList, *http.Response, error) {
	list := new(MacLeaseList)
	resp, err := s.client.get(MacLeaseNamespace, list)
	return list, resp, err
}

func (s *MacLeaseService) GetByUUID(id string) (*MacLease, *http.Response, error) {
	i := new(MacLease)
	resp, err := s.client.get(MacLeaseNamespace+"/"+id, i)
	return i, resp, err
}
