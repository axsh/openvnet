package openvnet

import (
	"net/http"
)

const InterfaceNamespace = "interfaces"

type Interface struct {
	ItemBase
	Mode                    string     `json:"mode"`
	DisplayName             string     `json:"display_name"`
	IngressFilteringEnabled bool       `json:"ingress_filtering_enabled"`
	EnableRouting           bool       `json:"enable_routing"`
	EnableRouteTranslation  bool       `json:"enable_route_translation"`
	EnableFiltering         bool       `json:"enable_filtering"`
	EnableLegacyFilering    bool       `json:"enable_legacy_filtering"`
	MacLeases               []MacLease `json:"mac_leases"`
	MacAddress              string     `json:"mac_address"`
	NetworkUUID             string     `json:"network_uuid"`
	Ipv4Address             string     `json:"ipv4_address"`
	IpLeases                []IpLease  `json:"ip_leases"`
}

type InterfaceList struct {
	ListBase
	Items []Interface `json:"items"`
}

type InterfaceService struct {
	*BaseService
}

type InterfaceCreateParams struct {
	UUID                    string `url:"uuid,omitempty"`
	IngressFilteringEnabled bool   `url:"ingress_filtering_enabled,omitempty"`
	EnableRouting           bool   `url:"enable_routing,omitempty"`
	EnableRouteTranslation  bool   `url:"enable_route_translation,omitempty"`
	OwnerDatapathUUID       string `url:"owner_datapath_uuid,omitempty"`
	EnableFiltering         bool   `url:"enable_filtering,omitempty"`
	SegmentUUID             string `url:"segment_uuid,omitempty"`
	NetworkUUID             string `url:"network_uuid,omitempty"`
	MacAddress              string `url:"mac_address,omitempty"`
	Ipv4Address             string `url:"ipv4_address,omitempty"`
	PortName                string `url:"port_name,omitempty"`
	Mode                    string `url:"mode,,omitempty"`
}

type InterfaceCreateSecurityGroup struct {
	UUID   string
	SGUUID string
}

func NewInterfaceService(client *Client) *InterfaceService {
	return &InterfaceService{
		BaseService: &BaseService{
			client:       client,
			namespace:    InterfaceNamespace,
			resource:     &Interface{},
			resourceList: &InterfaceList{},
		},
	}
}

func (s *InterfaceService) Create(params *InterfaceCreateParams) (*Interface, *http.Response, error) {
	item, resp, err := s.BaseService.Create(params)
	return item.(*Interface), resp, err
}

func (s *InterfaceService) Get() (*InterfaceList, *http.Response, error) {
	item, resp, err := s.BaseService.Get()
	return item.(*InterfaceList), resp, err
}

func (s *InterfaceService) GetByUUID(id string) (*Interface, *http.Response, error) {
	item, resp, err := s.BaseService.GetByUUID(id)
	return item.(*Interface), resp, err
}

func (s *InterfaceService) CreateSecurityGroupRelation(params *InterfaceCreateSecurityGroup) (*SecurityGroup, *http.Response, error) {
	sg := new(SecurityGroup)
	resp, err := s.client.post(InterfaceNamespace+"/"+params.UUID+"/security_groups/"+params.SGUUID, sg, nil)
	return sg, resp, err
}
