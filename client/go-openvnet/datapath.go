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

type DatapathList struct {
	ListBase
	Items []Datapath `json:"items"`
}

type DatapathService struct {
	*BaseService
}

type DatapathCreateParams struct {
	UUID        string `url:"uuid,omitempty"`
	DisplayName string `url:"display_name"`
	DPID        string `url:"dpid"`
	NodeId      string `url:"node_id"`
}

func NewDatapathService(client *Client) *DatapathService {
	s := &DatapathService{
		BaseService: &BaseService{
			client:           client,
			namespace:        DatapathNamespace,
			resource:         &Datapath{},
			resourceList:     &DatapathList{},
			relationServices: make(map[string]*RelationService),
		},
	}
	s.NewRelationService(&DatapathRelation{}, &NetworkList{}, "networks")
	s.NewRelationService(&DatapathRelation{}, &SegmentList{}, "segments")
	s.NewRelationService(&DatapathRelation{}, &RouteLinkList{}, "route_links")
	return s
}

func (s *DatapathService) Create(params *DatapathCreateParams) (*Datapath, *http.Response, error) {
	item, resp, err := s.BaseService.Create(params)
	return item.(*Datapath), resp, err
}

func (s *DatapathService) Get() (*DatapathList, *http.Response, error) {
	item, resp, err := s.BaseService.Get()
	return item.(*DatapathList), resp, err
}

func (s *DatapathService) GetByUUID(id string) (*Datapath, *http.Response, error) {
	item, resp, err := s.BaseService.GetByUUID(id)
	return item.(*Datapath), resp, err
}

///
///    Datapath Relations
///

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

type DatapathRelationCreateParams struct {
	InterfaceUUID string `url:"interface_uuid"`
	MacAddress    string `url:"mac_address,omitempty"`
}

//
// Deprecated, should use CreateRelation(), DeleteRelation(), GetRelations()
//

func (s *DatapathService) CreateDatapathRelation(rel *Relation, params *DatapathRelationCreateParams) (*DatapathRelation, *http.Response, error) {
	dpr := new(DatapathRelation)
	resp, err := s.client.post(DatapathNamespace+"/"+rel.BaseID+"/"+rel.Type+"/"+rel.RelationTypeUUID, &dpr, params)
	return dpr, resp, err
}

func (s *DatapathService) DeleteDatapathRelation(params *Relation) (*http.Response, error) {
	return s.client.del(DatapathNamespace + "/" + params.BaseID + "/" + params.Type + "/" + params.RelationTypeUUID)
}

func (s *DatapathService) GetNetworkRelations(uuid string) (*NetworkList, *http.Response, error) {
	list := new(NetworkList)
	resp, err := s.client.get(DatapathNamespace+"/"+uuid+"/networks", list)
	return list, resp, err
}

func (s *DatapathService) GetRouteLinkRelations(uuid string) (*RouteLinkList, *http.Response, error) {
	list := new(RouteLinkList)
	resp, err := s.client.get(DatapathNamespace+"/"+uuid+"/route_links", list)
	return list, resp, err
}

func (s *DatapathService) GetSegmentRelations(uuid string) (*SegmentList, *http.Response, error) {
	list := new(SegmentList)
	resp, err := s.client.get(DatapathNamespace+"/"+uuid+"/segments", list)
	return list, resp, err
}
