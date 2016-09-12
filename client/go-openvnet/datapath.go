package openvnet

import (
	"net/http"
)

const DatapathNamespace = "datapaths"

type Datapath struct {
	ItemBase
	DisplayName string `json:"display_name"`
	DPID        string `json:"dpid"`
	NodeId      string `json:"node_id"`
	IsConnected bool   `json:"is_connected"`
}

type DatapathRelation struct {
	ItemBase
	DPID          int    `json:"datapath_id"`
	NetworkID     int    `json:"network_id,omitempty"`
	SegmentID     int    `json:"segment_id,omitempty"`
	RouteLinkID   int    `json:"route_link_id,omitempty"`
	InterfaceID   int    `json:"interface_id"`
	MacAddresssID int    `json:"mac_address_id"`
	IpLeaseID     int    `json:"ip_lease_id"`
	MacAddress    string `json:"mac_address"`
}

type DatapathList struct {
	ListBase
	Items []Datapath `json:"items"`
}

type DatapathService struct {
	client *Client
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
	resp, err := s.client.post(DatapathNamespace, dp, params)
	return dp, resp, err
}

func (s *DatapathService) Delete(id string) (*http.Response, error) {
	return s.client.del(DatapathNamespace + "/" + id)
}

func (s *DatapathService) Get() (*DatapathList, *http.Response, error) {
	list := new(DatapathList)
	resp, err := s.client.get(DatapathNamespace, list)
	return list, resp, err
}

func (s *DatapathService) GetByUUID(id string) (*Datapath, *http.Response, error) {
	dp := new(Datapath)
	resp, err := s.client.get(DatapathNamespace+"/"+id, dp)
	return dp, resp, err
}

func (s *DatapathService) CreateDatapathRelation(rel *DatapathRelationType) (*DatapathRelation, *http.Response, error) {
	dpr := new(DatapathRelation)
	resp, err := s.client.post(DatapathNamespace+"/"+rel.DatapathID+"/"+rel.Type+"/"+rel.ID, dpr, rel.Params)
	return dpr, resp, err
}
