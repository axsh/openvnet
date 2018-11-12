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
	s := &TopologyService{
		BaseService: &BaseService{
			client:           client,
			namespace:        TopologyNamespace,
			resource:         &Topology{},
			resourceList:     &TopologyList{},
			relationServices: make(map[string]*RelationService),
		},
	}
	s.NewRelationService(&Network{}, &NetworkList{}, "networks")
	s.NewRelationService(&Segment{}, &SegmentList{}, "segments")
	s.NewRelationService(&Network{}, &RouteLinkList{}, "route_links")
	s.NewRelationService(&Datapath{}, &DatapathList{}, "datapaths")
	s.NewRelationService(nil, &TopologyLayerList{}, "underlays")
	return s
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
	ItemBase
	NetworkID   int `json:"network_id,omitempty"`
	SegmentID   int `json:"segment_id,omitempty"`
	RouteLinkID int `json:"route_link_id,omitempty"`
	OverlayID   int `json:"overlay_id,omitempty"`
	UnderlayID  int `json:"underlay_id,omitempty"`
}

type TopologyDatapathParams struct {
	InterfaceUUID string `url:"interface_uuid"`
}
