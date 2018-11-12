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
	*BaseService
}

type LeasePolicyCreateParams struct {
	UUID   string `url:"uuid,omitempty"`
	Timing string `url:"timing,omitempty"`
}

func NewLeasePolicyService(client *Client) *LeasePolicyService {
	s := &LeasePolicyService{
		BaseService: &BaseService{
			client:           client,
			namespace:        LeasePolicyNamespace,
			resource:         &LeasePolicy{},
			resourceList:     &LeasePolicyList{},
			relationServices: make(map[string]*RelationService),
		},
	}
	s.NewRelationService(&IpLeaseContainer{}, &IpLeaseContainerList{}, "ip_lease_containers")
	s.NewRelationService(&IpRetentionContainer{}, &IpRetentionContainerList{}, "ip_retention_containers")
	s.NewRelationService(&Network{}, &NetworkList{}, "networks")
	s.NewRelationService(&Interface{}, &InterfaceList{}, "interfaces")
	return s
}

func (s *LeasePolicyService) Create(params *LeasePolicyCreateParams) (*LeasePolicy, *http.Response, error) {
	item, resp, err := s.BaseService.Create(params)
	return item.(*LeasePolicy), resp, err
}

func (s *LeasePolicyService) Get() (*LeasePolicyList, *http.Response, error) {
	item, resp, err := s.BaseService.Get()
	return item.(*LeasePolicyList), resp, err
}

func (s *LeasePolicyService) GetByUUID(id string) (*LeasePolicy, *http.Response, error) {
	item, resp, err := s.BaseService.GetByUUID(id)
	return item.(*LeasePolicy), resp, err
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
