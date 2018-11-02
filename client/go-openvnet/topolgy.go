package openvnet

import (
	"net/http"
)

const TopologyNamespace = "topologies"

type Topology struct {
	ItemBase
	Mode string `json:"mode"`
}

type TopologyList struct {
	ListBase
	Items []Topology `json:"items"`
}

type TopologyLayerList struct {
	ListBase
	Items []struct {
		ItemBase
		UUID string `json:"uuid"`
		Mode string `json:"mode"`
	}
}

type TopologyDatapathList struct {
	ListBase
	Items []struct {
		ItemBase
		TopologyID  int `json:"topology_id"`
		DatapathID  int `json:"datapath_id"`
		InterfaceID int `json:"interface_id"`
	}
}

type TopologyService struct {
	*BaseService
}

type TopologyCreateParams struct {
	UUID string `url:"uuid,omitempty"`
	Mode string `url:"mode,omitempty"`
}

func NewTopologyService(client *Client) *TopologyService {
	return &TopologyService{
		BaseService: &BaseService{
			client:       client,
			namespace:    TopologyNamespace,
			resource:     &Topology{},
			resourceList: &TopologyList{},
		},
	}
}

func (s *TopologyService) Create(params *TopologyCreateParams) (*Topology, *http.Response, error) {
	item, resp, err := s.BaseService.Create(params)
	return item.(*Topology), resp, err
}

func (s *TopologyService) Get() (*TopologyList, *http.Response, error) {
	item, resp, err := s.BaseService.Get()
	return item.(*TopologyList), resp, err
}

func (s *TopologyService) GetByUUID(id string) (*Topology, *http.Response, error) {
	item, resp, err := s.BaseService.GetByUUID(id)
	return item.(*Topology), resp, err
}

type TopologyRelation struct {
	Type             string
	TopologyUUID     string
	RelationTypeUUID string
	Body             struct {
		ItemBase
		NetworkID   int `json:"network_id,omitempty"`
		SegmentID   int `json:"segment_id,omitempty"`
		RouteLinkID int `json:"route_link_id,omitempty"`
		OverlayID   int `json:"overlay_id,omitempty"`
		UnderlayID  int `json:"underlay_id,omitempty"`
	}
}

type TopologyDatapathParams struct {
	InterfaceUUID string `url:"interface_uuid"`
}

func (s *TopologyService) CreateTopologyRelation(rel *TopologyRelation, params interface{}) (*TopologyRelation, *http.Response, error) {
	tpr := rel
	resp, err := s.client.post(TopologyNamespace+"/"+tpr.TopologyUUID+"/"+tpr.Type+"/"+tpr.RelationTypeUUID, &tpr.Body, params)
	return tpr, resp, err
}

func (s *TopologyService) DeleteTopologyRelation(params *TopologyRelation) (*http.Response, error) {
	return s.client.del(TopologyNamespace + "/" + params.TopologyUUID + "/" + params.Type + "/" + params.RelationTypeUUID)
}

func (s *TopologyService) GetNetworkRelations(uuid string) (*NetworkList, *http.Response, error) {
	list := new(NetworkList)
	resp, err := s.client.get(TopologyNamespace+"/"+uuid+"/networks", list)
	return list, resp, err
}

func (s *TopologyService) GetRouteLinkRelations(uuid string) (*RouteLinkList, *http.Response, error) {
	list := new(RouteLinkList)
	resp, err := s.client.get(TopologyNamespace+"/"+uuid+"/route_links", list)
	return list, resp, err
}

func (s *TopologyService) GetSegmentRelations(uuid string) (*SegmentList, *http.Response, error) {
	list := new(SegmentList)
	resp, err := s.client.get(TopologyNamespace+"/"+uuid+"/segments", list)
	return list, resp, err
}

func (s *TopologyService) GetLayerRelations(uuid string) (*TopologyLayerList, *http.Response, error) {
	list := new(TopologyLayerList)
	resp, err := s.client.get(TopologyNamespace+"/"+uuid+"/underlays", list)
	return list, resp, err
}

func (s *TopologyService) GetDatapathRelations(uuid string) (*TopologyDatapathList, *http.Response, error) {
	list := new(TopologyDatapathList)
	resp, err := s.client.get(TopologyNamespace+"/"+uuid+"/datapaths", list)
	return list, resp, err
}
