package openvnet

import (
	"net/http"
)

const LeasePolicyNamespace = "lease_policies"

type LeasePolicy struct {
	ItemBase
	Mode   string `json:"mode,omitempty"`
	Timing string `json:"timing,omitempty"`
}

type LeasePolicyList struct {
	ListBase
	Items []LeasePolicy `json:"items"`
}

type LeasePolicyService struct {
	client *Client
}

type LeasePolicyCreateParams struct {
	UUID   string `url:"uuid,omitempty"`
	Timing string `url:"timing,omitempty"`
}

func (s *LeasePolicyService) Create(params *LeasePolicyCreateParams) (*LeasePolicy, *http.Response, error) {
	lp := new(LeasePolicy)
	resp, err := s.client.post(LeasePolicyNamespace, lp, params)
	return lp, resp, err
}

func (s *LeasePolicyService) Delete(id string) (*http.Response, error) {
	return s.client.del(LeasePolicyNamespace + "/" + id)
}

func (s *LeasePolicyService) Get() (*LeasePolicyList, *http.Response, error) {
	list := new(LeasePolicyList)
	resp, err := s.client.get(LeasePolicyNamespace, list)
	return list, resp, err
}

func (s *LeasePolicyService) GetByUUID(id string) (*LeasePolicy, *http.Response, error) {
	lp := new(LeasePolicy)
	resp, err := s.client.get(LeasePolicyNamespace+"/"+id, lp)
	return lp, resp, err
}

///
///    LeasePolicy Relations
///

type LeasePolicyRelation struct {
	ItemBase
	IpRetentionContainer
}

type LeasePolicyRelationCreateParams struct {
	IpRangeGroupUUID string `url:"ip_range_group_uuid"`
}

func (s *LeasePolicyService) CreateLeasePolicyRelation(rel *Relation, params *LeasePolicyRelationCreateParams) (*LeasePolicyRelation, *http.Response, error) {
	lpr := new(LeasePolicyRelation)
	resp, err := s.client.post(LeasePolicyNamespace+"/"+rel.BaseID+"/"+rel.Type+"/"+rel.RelationTypeUUID, &lpr, params)
	return lpr, resp, err
}

func (s *LeasePolicyService) DeleteLeasePolicyRelation(params *Relation) (*http.Response, error) {
	return s.client.del(LeasePolicyNamespace + "/" + params.BaseID + "/" + params.Type + "/" + params.RelationTypeUUID)
}

func (s *LeasePolicyService) GetIpRetentionContainerRelations(uuid string) (*IpRetentionContainerList, *http.Response, error) {
	list := new(IpRetentionContainerList)
	resp, err := s.client.get(LeasePolicyNamespace+"/"+uuid+"/ip_retention_containers", list)
	return list, resp, err
}

func (s *LeasePolicyService) GetIpLeaseContainerRelations(uuid string) (*IpLeaseContainerList, *http.Response, error) {
	list := new(IpLeaseContainerList)
	resp, err := s.client.get(LeasePolicyNamespace+"/"+uuid+"/ip_lease_containers", list)
	return list, resp, err
}

func (s *LeasePolicyService) GetNetworkRelations(uuid string) (*NetworkList, *http.Response, error) {
	list := new(NetworkList)
	resp, err := s.client.get(LeasePolicyNamespace+"/"+uuid+"/networks", list)
	return list, resp, err
}

func (s *LeasePolicyService) GetInterfaceRelations(uuid string) (*InterfaceList, *http.Response, error) {
	list := new(InterfaceList)
	resp, err := s.client.get(LeasePolicyNamespace+"/"+uuid+"/interfaces", list)
	return list, resp, err
}
