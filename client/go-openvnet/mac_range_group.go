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
	*BaseService
}

type MacRangeGroupCreateParams struct {
	UUID           string `url:"uuid,omitempty"`
	AllocationType string `url:"allocation_type,omitempty"`
}

func NewMacRangeGroupService(client *Client) *MacRangeGroupService {
	return &MacRangeGroupService{
		BaseService: &BaseService{
			client:       client,
			namespace:    MacRangeGroupNamespace,
			resource:     &MacRangeGroup{},
			resourceList: &MacRangeGroupList{},
		},
	}
}

func (s *MacRangeGroupService) Create(params *MacRangeGroupCreateParams) (*MacRangeGroup, *http.Response, error) {
	item, resp, err := s.BaseService.Create(params)
	return item.(*MacRangeGroup), resp, err
}

func (s *MacRangeGroupService) Get() (*MacRangeGroupList, *http.Response, error) {
	item, resp, err := s.BaseService.Get()
	return item.(*MacRangeGroupList), resp, err
}

func (s *MacRangeGroupService) GetByUUID(id string) (*MacRangeGroup, *http.Response, error) {
	item, resp, err := s.BaseService.GetByUUID(id)
	return item.(*MacRangeGroup), resp, err
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
	BeginMacAddress string `url:"begin_mac_address,omitempty"`
	EndMacAddress   string `url:"end_mac_address,omitempty"`
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
