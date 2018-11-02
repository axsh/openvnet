package openvnet

import (
	"net/http"
)

const SecurityGroupNamespace = "security_groups"

type SecurityGroup struct {
	UUID        string `json:"uuid"`
	DisplayName string `json:"display_name"`
	Rules       string `json:"rules"`
	Description string `json:"description"`
}

type SecurityGroupList struct {
	ListBase
	Items []SecurityGroup
}

type SecurityGroupService struct {
	*BaseService
}

type SecurityGroupCreateParams struct {
	UUID        string   `url:"uuid,omitempty"`
	DisplayName string   `url:"display_name,omitempty"`
	Description string   `url:"description,omitempty"`
	Rules       []string `url:"rules,omitempty"`
}

func NewSecurityGroupService(client *Client) *SecurityGroupService {
	return &SecurityGroupService{
		BaseService: &BaseService{
			client:       client,
			namespace:    SecurityGroupNamespace,
			resource:     &SecurityGroup{},
			resourceList: &SecurityGroupList{},
		},
	}
}

func (s *SecurityGroupService) Create(params *SecurityGroupCreateParams) (*SecurityGroup, *http.Response, error) {
	item, resp, err := s.BaseService.Create(params)
	return item.(*SecurityGroup), resp, err
}

func (s *SecurityGroupService) Get() (*SecurityGroupList, *http.Response, error) {
	item, resp, err := s.BaseService.Get()
	return item.(*SecurityGroupList), resp, err
}

func (s *SecurityGroupService) GetByUUID(id string) (*SecurityGroup, *http.Response, error) {
	item, resp, err := s.BaseService.GetByUUID(id)
	return item.(*SecurityGroup), resp, err
}
