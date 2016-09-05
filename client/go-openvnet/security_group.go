package openvnet

import (
	"net/http"
	"strings"
)

const SecurityGroupNamespace = "security_groups"

type SecurityGroup struct {
	UUID        string `json:"uudi"`
	DisplayName string `json:"display_name"`
	Rules       string `json:"rules"`
	Description string `json:"description"`
}

type SecurityGroupService struct {
	client *Client
}

type SecurityGroupCreateParams struct {
	UUID        string `url:"uudi,omitempty"`
	DisplayName string `url:"display_name,omitempty"`
	Description string `url:"description,omitempty"`
	Rules       []string `url:"rules,omitempty"`
}

func (s *SecurityGroupService) Create (params *SecurityGroupCreateParams) (*SecurityGroup, *http.Response, error) {
	sg := new(SecurityGroup)
	params.Rules = []string{strings.Join(params.Rules,"\n")}
	resp, err := s.client.post(SecurityGroupNamespace, sg, params)
	return sg, resp, err
}

func (s *SecurityGroupService) Delete (id string) (*http.Response, error) {
	return s.client.del(id)
}
