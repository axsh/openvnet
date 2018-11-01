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
	client *Client
}

type IpLeaseContainerCreateParams struct {
	UUID string `url:"uuid,omitempty"`
}

func (s *IpLeaseContainerService) Create(params *IpLeaseContainerCreateParams) (*IpLeaseContainer, *http.Response, error) {
	ilc := new(IpLeaseContainer)
	resp, err := s.client.post(IpLeaseContainerNamespace, ilc, params)
	return ilc, resp, err
}

func (s *IpLeaseContainerService) Delete(id string) (*http.Response, error) {
	return s.client.del(IpLeaseContainerNamespace + "/" + id)
}

func (s *IpLeaseContainerService) Get() (*IpLeaseContainerList, *http.Response, error) {
	list := new(IpLeaseContainerList)
	resp, err := s.client.get(IpLeaseContainerNamespace, list)
	return list, resp, err
}

func (s *IpLeaseContainerService) GetByUUID(id string) (*IpLeaseContainer, *http.Response, error) {
	lp := new(IpLeaseContainer)
	resp, err := s.client.get(IpLeaseContainerNamespace+"/"+id, lp)
	return lp, resp, err
}
