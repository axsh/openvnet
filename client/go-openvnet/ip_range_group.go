package openvnet

import "net/http"

const IpRangeGroupNamespace = "ip_range_groups"

type IpRangeGroup struct {
	ItemBase
	AllocationType string `json:"allocation_type"`
}

type IpRangeGroupList struct {
	ListBase
	Items []IpRangeGroup `json:"items"`
}

type IpRangeGroupService struct {
	client *Client
}

type IpRangeGroupCreateParams struct {
	UUID           string `url:"uuid,omitempty"`
	AllocationType string `url:"allocation_type,omitempty"`
}

func (s *IpRangeGroupService) Create(params *IpRangeGroupCreateParams) (*IpRangeGroup, *http.Response, error) {
	iprg := new(IpRangeGroup)
	resp, err := s.client.post(IpRangeGroupNamespace, iprg, params)
	return iprg, resp, err
}

func (s *IpRangeGroupService) Delete(id string) (*http.Response, error) {
	return s.client.del(IpRangeGroupNamespace + "/" + id)
}

func (s *IpRangeGroupService) Get() (*IpRangeGroupList, *http.Response, error) {
	list := new(IpRangeGroupList)
	resp, err := s.client.get(IpRangeGroupNamespace, list)
	return list, resp, err
}

func (s *IpRangeGroupService) GetByUUID(id string) (*IpRangeGroup, *http.Response, error) {
	i := new(IpRangeGroup)
	resp, err := s.client.get(IpRangeGroupNamespace+"/"+id, i)
	return i, resp, err
}

///
///    Ip Range
///

type IpRange struct {
	ItemBase
	IpRangeGroupID   int `json:"ip_range_group_id"`
	BeginIpv4Address int `json:"begin_ipv4_address"`
	EndIpv4Address   int `json:"end_ipv4_address"`
}

type IpRangeList struct {
	ListBase
	Items []IpRange
}

type IpRangeCreateParams struct {
	BeginIpv4Address string `url:"begin_ipv4_address,omitempty"`
	EndIpv4Address   string `url:"end_ipv4_address,omitempty"`
}

func (s *IpRangeGroupService) CreateRange(uuid string, params *IpRangeCreateParams) (*IpRange, *http.Response, error) {
	ipr := new(IpRange)
	resp, err := s.client.post(IpRangeGroupNamespace+"/"+uuid+"/ip_ranges", ipr, params)
	return ipr, resp, err
}

func (s *IpRangeGroupService) DeleteRange(iprgUUID string, iprUUID string) (*http.Response, error) {
	return s.client.del(IpRangeGroupNamespace + "/" + iprgUUID + "/ip_ranges/" + iprUUID)
}

func (s *IpRangeGroupService) GetRange(uuid string) (*IpRangeList, *http.Response, error) {
	list := new(IpRangeList)
	resp, err := s.client.get(IpRangeGroupNamespace+"/"+uuid+"/ip_ranges", list)
	return list, resp, err
}
