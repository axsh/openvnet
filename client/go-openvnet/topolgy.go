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
	Items[]Topology `json:"items"`
}

type TopologyService struct {
	client *Client
}

type TopologyCreateParams struct {
	UUID string `url:"uuid,omitempty"`
	Mode string `url:"mode,omitempty"`
}

func (s *TopologyService) Create(params *TopologyCreateParams) (*Topology, *http.Response, error) {
	tp :=new(Topology)
	resp, err := s.client.post(TopologyNamespace, tp, params)
	return tp, resp, err
}

func (s *TopologyService) Delete(id string) (*http.Response, error) {
	return s.client.del(TopologyNamespace + "/" + id)
}

func (s *TopologyService) Get() (*TopologyList, *http.Response, error) {
	list := new(TopologyList)
	resp, err := s.client.get(TopologyNamespace, list)
	return list, resp, err
}

func (s *TopologyService) GetByUUID(id string) (*Topology, *http.Response, error) {
	dp := new(Topology)
	resp, err := s.client.get(TopologyNamespace+"/"+id, dp)
	return dp, resp, err
}

type TopologyRelation struct {
	Type             string
	TopologyUUID     string
	RelationTypeUUID string
	Body     struct {
		ItemBase
		NetworkID   int `json:"network_id,omitempty"`
		SegmentID   int `json:"segment_id,omitempty"`
		RouteLinkID int `json:"route_link_id,omitempty"`
	}
}

func (s *TopologyService) CreateTopologyRelation(rel *TopologyRelation) (*TopologyRelation, *http.Response, error) {
	tpr := rel
	resp, err := s.client.post(TopologyNamespace+"/"+tpr.TopologyUUID+"/"+tpr.Type+"/"+tpr.RelationTypeUUID, &tpr.Body, nil)
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
