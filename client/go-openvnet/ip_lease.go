package openvnet

import "net/http"

const IpLeaseNamespace = "ip_leases"

type IpLease struct {
	ItemBase
	InterfaceID   int    `json:"interface_id"`
	MacLeaseID    int    `json:"mac_lease_id"`
	IPAddressID   int    `json:"ip_address_id"`
	EnableRouting bool   `json:"enable_routing"`
	NetworkID     int    `json:"network_id"`
	IPv4Address   string `json:"ipv4_address"`
	IPAddress     struct {
		ItemBase
		ID         int     `json:"id"`
		NetworkID  int     `json:"network_id"`
		IPv4Adress int     `json:"ipv4_address"`
		Network    Network `json:"network"`
	} `json:"ip_adress"`
	InterfaceUUID string `json:"interface_uuid"`
	MacLeaseUUID  string `json:"mac_lease_uuid"`
	NetworkUUID   string `json:"network_uuid"`
}

type IpLeaseList struct {
	ListBase
	Items []IpLease `json:"items"`
}

type IpLeaseService struct {
	client *Client
}

type IpLeaseCreateParams struct {
	UUID          string `url:"uuid,omitempty"`
	IPv4Address   string `url:"ipv4_address"`
	InterfaceUUID string `url:"interface_uuid,omitempty"`
	NetworkUUID   string `url:"network_uuid"`
	MacLeaseUUID  string `url:"mac_lease_uuid,omitempty"`
	EnableRouting bool   `url:"enable_routing,omitempty"`
}

type IpLeaseAttachParams struct {
	InterfaceUUID string `url:"interface_uuid,omitempty"`
	MacLeaseUUID  string `url:"mac_lease_uuid,omitempty"`
}

func (s *IpLeaseService) Create(params *IpLeaseCreateParams) (*IpLease, *http.Response, error) {
	il := new(IpLease)
	resp, err := s.client.post(IpLeaseNamespace, il, params)
	return il, resp, err
}

func (s *IpLeaseService) Delete(id string) (*http.Response, error) {
	return s.client.del(IpLeaseNamespace + "/" + id)
}

func (s *IpLeaseService) Get() (*IpLeaseList, *http.Response, error) {
	list := new(IpLeaseList)
	resp, err := s.client.get(IpLeaseNamespace, list)
	return list, resp, err
}

func (s *IpLeaseService) GetByUUID(id string) (*IpLease, *http.Response, error) {
	i := new(IpLease)
	resp, err := s.client.get(IpLeaseNamespace+"/"+id, i)
	return i, resp, err
}

func (s *IpLeaseService) Attach(id string, params *IpLeaseAttachParams) (*IpLease, *http.Response, error) {
	il := new(IpLease)
	resp, err := s.client.put(IpLeaseNamespace+"/"+id+"/attach", il, params)
	return il, resp, err
}

func (s *IpLeaseService) Release(id string) (*IpLease, *http.Response, error) {
	il := new(IpLease)
	resp, err := s.client.put(IpLeaseNamespace+"/"+id+"/release", il, nil)
	return il, resp, err

}