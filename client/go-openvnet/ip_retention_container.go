package openvnet

import "net/http"

const IpRetentionContainerNamespace = "ip_retention_containers"

type IpRetentionContainer struct {
	ItemBase
	LeaseTime int `json:"lease_time,omitempty"`
	GraceTime int `json:"grace_time,omitempty"`
}

type IpRetentionContainerList struct {
	ListBase
	Items []IpRetentionContainer `json:"items"`
}

type IpRetentionContainerService struct {
	client *Client
}

type IpRetentionContainerCreateParams struct {
	UUID      string `url:"uuid"`
	LeaseTime int    `url:"lease_time,omitempty"`
	GraceTime int    `url:"grace_time,omitempty"`
}

func (s *IpRetentionContainerService) Create(params *IpRetentionContainerCreateParams) (*IpRetentionContainer, *http.Response, error) {
	irc := new(IpRetentionContainer)
	resp, err := s.client.post(IpRetentionContainerNamespace, irc, params)
	return irc, resp, err
}

func (s *IpRetentionContainerService) Delete(id string) (*http.Response, error) {
	return s.client.del(IpRetentionContainerNamespace + "/" + id)
}

func (s *IpRetentionContainerService) Get() (*IpRetentionContainerList, *http.Response, error) {
	list := new(IpRetentionContainerList)
	resp, err := s.client.get(IpRetentionContainerNamespace, list)
	return list, resp, err
}

func (s *IpRetentionContainerService) GetByUUID(id string) (*IpRetentionContainer, *http.Response, error) {
	lp := new(IpRetentionContainer)
	resp, err := s.client.get(IpRetentionContainerNamespace+"/"+id, lp)
	return lp, resp, err
}
