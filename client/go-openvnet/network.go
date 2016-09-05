package openvnet

import (
	"net/http"
)

const NetworkNamespace = "networks"

type Network struct {
	ID           int    `json:"id"`
	UUID         string `json:"uuid"`
	DisplayName  string `json:"display_name"`
	Ipv4Network  string `json:"ipv4_network"`
	Ipv4Prefix   string `json:"ipv4_prefix"`
	NetworkMode  string `json:"network_mode"`
	DomainName   string `json:"domain_name"`
	CreatedAt    string `json:"created_at"`
	UpdatedAt    string `json:"updated_at"`
	DeletedAt    string `json:"deleted_at"`
	SegmentID    int    `json:"segment_id"`
	IsDeleted    bool   `json:"id_deleted"`
}

type NetworkService struct {
	client *Client

	Namespace string
}

type NetworkCreateParams struct {
	UUID         string `url:"uuid,omitempty"`
	DisplayName  string `url:"display_name,omitempty"`
	Ipv4Network  string `url:"ipv4_network"`
	Ipv4Prefix   int    `url:"ipv4_prefix,omitempty"`
	NetworkMode  string `url:"network_mode"`
	DomainName   string `url:"domain_name,omitempty"`
	SegmentUUID  string `url:"segment_id,omitempty"`
}

func (s *NetworkService) Create(params *NetworkCreateParams) (*Network, *http.Response, error) {
	nw := new(Network)
	resp, err := s.client.post(NetworkNamespace, nw, params)
	return nw, resp, err
}

func (s *NetworkService) Delete(id string) (*http.Response, error) {
	return s.client.del(NetworkNamespace +"/"+ id)
}
