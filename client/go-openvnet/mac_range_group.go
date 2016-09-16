package openvnet

import "net/http"

const MacRangeGroupNamespace = "mac_range_groups"

type MacRangeGroup struct {
	ItemBase
	AllocationType string `json:"allocation_type"`
}

type MacRangeGroupList struct {
	ListBase
	Items []MacRangeGroup `json:"items"`
}

type MacRangeGroupService struct {
	client *Client
}

type MacRangeGroupCreateParams struct {
	UUID           string `url:"uuid,omitempty"`
	AllocationType string `url:"allocation_type,omitempty"`
}

func (s *MacRangeGroupService) Create(params *MacRangeGroupCreateParams) (*MacRangeGroup, *http.Response, error) {
	mrg := new(MacRangeGroup)
	resp, err := s.client.post(MacRangeGroupNamespace, mrg, params)
	return mrg, resp, err
}

func (s *MacRangeGroupService) Delete(id string) (*http.Response, error) {
	return s.client.del(MacRangeGroupNamespace + "/" + id)
}

func (s *MacRangeGroupService) Get() (*MacRangeGroupList, *http.Response, error) {
	list := new(MacRangeGroupList)
	resp, err := s.client.get(MacRangeGroupNamespace, list)
	return list, resp, err
}

func (s *MacRangeGroupService) GetByUUID(id string) (*MacRangeGroup, *http.Response, error) {
	i := new(MacRangeGroup)
	resp, err := s.client.get(MacRangeGroupNamespace+"/"+id, i)
	return i, resp, err
}

///
///    Mac Range
///

type MacRange struct {
	ItemBase
	MacRangeGroupID int `json:"mac_range_group_id"`
	BeginMacAddress int `json:"begin_mac_address"`
	EndMacAddress   int `json:"end_mac_address"`
}

type MacRangeList struct {
	ListBase
	Items []MacRange
}

type MacRangeCreateParams struct {
	BeginMacAddress string `url:"begin_mac_address"`
	EndMacAddress   string `url:"end_mac_address"`
}

func (s *MacRangeGroupService) CreateRange(uuid string, params *MacRangeCreateParams) (*MacRange, *http.Response, error) {
	mr := new(MacRange)
	resp, err := s.client.post(MacRangeGroupNamespace+"/"+uuid+"/mac_ranges", mr, params)
	return mr, resp, err
}

func (s *MacRangeGroupService) DeleteRange(mrgUUID string, mrUUID string) (*http.Response, error) {
	return s.client.del(MacRangeGroupNamespace + "/" + mrgUUID + "/mac_ranges/" + mrUUID)
}

func (s *MacRangeGroupService) GetRange(uuid string) (*MacRangeList, *http.Response, error) {
	list := new(MacRangeList)
	resp, err := s.client.get(MacRangeGroupNamespace+"/"+uuid+"/mac_ranges", list)
	return list, resp, err
}
