package openvnet

import (
	"net/http"
)

const Namespace = "datapaths"

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

type DatapathRelation struct {
	ID            int    `json:"id"`
	DPID          int    `json:"datapath_id"`
	NetworkID     int    `json:"network_id,omitempty"`
	SegmentID     int    `json:"segment_id,omitempty"`
	RouteLinkID   int    `json:"route_link_id,omitempty"`
	InterfaceID   int    `json:"interface_id"`
	MacAddresssID int    `json:"mac_address_id"`
	IpLeaseID     int    `json:"ip_lease_id"`
	CreatedAt     string `json:"mac_address"`
	UpdatedAt     string `json:"created_at"`
	DeletedAt     string `json:"deleted_at"`
	IsDeleted     int    `json:"is_deleted"`
	MacAddress    string `json:"mac_address"`
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

type DatapathRelationType struct {
	Params     *DatapathRelationCreateParams
	DatapathID string
	Type       string
	ID         string
}

type DatapathRelationCreateParams struct {
	InterfaceUUID string `url:"interface_uuid"`
	MacAddress    string `url:"mac_address,omitempty"`
}

func (s *DatapathService) Create(params *DatapathCreateParams) (*Datapath, *http.Response, error) {
	dp := new(Datapath)
	ovnError := new(OpenVNetError)
	resp, err := s.client.sling.New().Post(s.Namespace).BodyForm(params).Receive(dp, ovnError)
	return dp, resp, err
}

func (s *DatapathService) Delete(id string) (*http.Response, error) {
	return s.client.sling.New().Delete(s.Namespace +"/"+ id).Receive(nil, new(OpenVNetError))
}

func (s *DatapathService) CreateDatapathRelation(rel*DatapathRelationType) (*DatapathRelation, *http.Response, error) {
	dpr := new(DatapathRelation)
	ovnError := new(OpenVNetError)
	ns := s.Namespace +"/"+ rel.DatapathID +"/"+ rel.Type +"/"+ rel.ID

	resp, err := s.client.sling.New().Post(ns).BodyForm(rel.Params).Receive(dpr, ovnError)

	return dpr, resp, err
}
