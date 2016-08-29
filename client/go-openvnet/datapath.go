package openvnet

import (
	"net/http"
)

type Datapath struct {
	ID          int    `json:"id"`
	UUID        string `json:"uuid"`
	DisplayName string `json:"display_name"`
	DPID        string `json:"dpid"`
	NodeId      string `json:"node_id"`
	IsConnected bool   `json:"is_connected"`
	CreatedAt   string `json:"created_at"`
	DeletedAt   string `json:"deleted_at"`
}

type DatapathService struct {
	client *Client

	Namespace string
}

type DatapathCreateParams struct {
	UUID        string `url:"uuid"`
	DisplayName string `url:"display_name"`
	DPID        string `url:"dpid"`
	NodeId      string `url:"node_id"`
}

func (s *DatapathService) Create(params *DatapathCreateParams) (*Datapath, *http.Response, error) {
	dp := new(Datapath)
	ovnError := new(OpenVNetError)
	resp, err := s.client.sling.New().Post(s.Namespace).BodyForm(params).Receive(dp, ovnError)
	return dp, resp, err
}

func (s *DatapathService) Delete(id string) (*http.Response, error) {
	return nil, nil
}
