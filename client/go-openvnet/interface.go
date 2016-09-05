package openvnet

import (
	"net/http"
)

const InterfaceNamespace = "interfaces"

type Interface struct {
	ID                      int        `json:"id"`
	UUID                    string     `json:"uuid"`
	Mode                    string     `json:"mode"`
	DisplayName             string     `json:"display_name"`
	IngressFilteringEnabled bool       `json:"ingress_filtering_enabled"`
	EnableRouting           bool       `json:"enable_routing"`
	EnableRouteTranslation  bool       `json:"enable_route_translation"`
	CreatedAt               string     `json:"created_at"`
	UpdatedAt               string     `json:"updated_at"`
	DeletedAt               string     `json:"deleted_at"`
	IsDeleted               int        `json:"is_deleted"`
	EnableFiltering         bool       `json:"enable_filtering"`
	EnableLegacyFilering    bool       `json:"enable_legacy_filtering"`
	MacLeases               []MacLease `json:"mac_leases"`
	MacAddress              string     `json:"mac_address"`
	NetworkUUID             string     `json:"network_uuid"`
	IPv4Adress              string     `json:"ipv4_address"`
	IPLeases                []IpLease  `json:"ip_leases"`
}

type InterfaceService struct {
	client *Client
}

type InterfaceCreateParams struct {
	UUID                    string `url:"uuid,omitempty"`
	IngressFilteringEnabled bool   `url:"ingress_filtering_enabled,omitempty"`
	EnableRouting           bool   `url:"enable_routing,omitempty"`
	EnableRouteTranslation  bool   `url:"enable_route_translation,omitempty"`
	OwnerDatapathID         string `url:"owner_datapath_id,omitempty"`
	EnableFiltering         bool   `url:"enable_filtering,omitempty"`
	SegmentUUID             string `url:"segment_uuid,omitempty"`
	NetworkUUID             string `url:"network_uuid"`
	MacAddress              string `url:"mac_address,omitempty"`
	Ipv4Address             string `url:"ipv4_address,omitempty"`
	PortName                string `url:"port_name,omitempty"`
	Mode                    string `url:"mode,,omitempty"`
}

type InterfaceCreateSecurityGroup struct {
	UUID   string
	SGUUID string
}

func (s *InterfaceService) Create(params *InterfaceCreateParams) (*Interface, *http.Response, error) {
	i := new(Interface)
	resp, err := s.client.post(InterfaceNamespace, i, params)
	return i, resp, err
}

func (s *InterfaceService) Delete(id string) (*http.Response, error) {
	return s.client.del(InterfaceNamespace +"/"+ id)
}

func (s *InterfaceService) CreateSecurityGroupRelation (params InterfaceCreateSecurityGroup) (*SecurityGroup, *http.Response, error) {
	sg := new(SecurityGroup)
	resp, err := s.client.post(InterfaceNamespace +"/"+ params.UUID + "/securty_groups/" + params.SGUUID, sg, nil)
	return sg, resp, err
}
