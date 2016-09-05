package openvnet

import (
	"net/http"
)

const InterfaceNamespace = "interfaces"

type Interface struct {
	ID                      int    `json:"id"`
	UUID                    string `json:"uuid"`
	Mode                    string `json:"mode"`
	DisplayName             string `json:"display_name"`
	IngressFilteringEnabled bool   `json:"ingress_filtering_enabled"`
	EnableRouting           bool   `json:"enable_routing"`
	EnableRouteTranslation  bool   `json:"enable_route_translation"`
	CreatedAt               string `json:"created_at"`
	UpdatedAt               string `json:"updated_at"`
	DeletedAt               string `json:"deleted_at"`
	IsDeleted               int    `json:"is_deleted"`
	EnableFiltering         bool   `json:"enable_filtering"`
	EnableLegacyFilering    bool   `json:"enable_legacy_filtering"`
	MacLeases               []struct {
		ID           int    `json:"id"`
		UUID         string `json:"uuid"`
		InterfaceID  int    `json:"interface_id"`
		MacAddressID int    `json:"mac_address_id"`
		CreatedAt    string `json:"created_at"`
		UpdatedAt    string `json:"updated_at"`
		DeletedAt    string `json:"deleted_at"`
		IsDeleted    int    `json:"is_deleted"`
		MacAddress   string `json:"mac_address"`
		SegmentID    int    `json:"segment_id"`
		IPLeases     []struct {
			ID            int    `json:"id"`
			UUID          string `json:"uuid"`
			InterfaceID   int    `json:"interface_id"`
			MacLeaseID    int    `json:"mac_lease_id"`
			IPAddressID   int    `json:"ip_address_id"`
			EnableRouting bool   `json:"enable_routing"`
			CreatedAt     string `json:"created_at"`
			UpdatedAt     string `json:"updated_at"`
			DeletedAt     string `json:"deleted_at"`
			IsDeleted     int    `json:"is_deleted"`
			NetworkID     int    `json:"network_id"`
			IPv4Adress    string `json:"ipv4_address"`
			IPAddress     struct {
				ID            int    `json:"id"`
				NetworkID     int    `json:"network_id"`
				IPv4Adress    int    `json:"ipv4_address"`
				CreatedAt     string `json:"created_at"`
				DeletedAt     string `json:"deleted_at"`
				UpdatedAt     string `json:"updated_at"`
				IsDeleted     int    `json:"is_deleted"`
				Network       struct {
					ID          int    `json:"id"`
					UUID        string `json:"uudi"`
					DisplayName string `json:"display_name"`
					IPv4Network int    `json:"ipv4_network"`
					IPv4Prefix  int    `json:"ipv4_prefix"`
					NetworkMode string `json:"network_mode"`
					DomainName  string `json:"domain_named"`
					UpdatedAt   string `json:"updated_at"`
					CreatedAt   string `json:"created_at"`
					DeletedAt   string `json:"deleted_at"`
					IsDeleted   int    `json:"is_deleted"`
					SegmentID   int    `json:"segment_id"`
				} `json:"network"`
			} `json:"ip_adress"`
			InterfaceUUID string `json:"interface_uuid"`
			MacLeaseUUID  string `json:"mac_lease_uuid"`
			NetworkUUID   string `json:"network_uuid"`
		} `json:"ip_leases"`
		InterfaceUUID string `json:"interface_uuid"`
	} `json:"mac_leases"`
	MacAddress   string `json:"mac_address"`
	NetworkUUID string `json:"network_uuid"`
	IPv4Adress  string `json:"ipv4_address"`
	IPLeases     []struct {
		ID            int    `json:"id"`
		UUID          string `json:"uuid"`
		InterfaceID   int    `json:"interface_id"`
		MacLeaseID    int    `json:"mac_lease_id"`
		IPAddressID   int    `json:"ip_address_id"`
		EnableRouting bool   `json:"enable_routing"`
		CreatedAt     string `json:"created_at"`
		UpdatedAt     string `json:"updated_at"`
		DeletedAt     string `json:"deleted_at"`
		IsDeleted     int    `json:"is_deleted"`
		NetworkID     int    `json:"network_id"`
		IPv4Adress    string `json:"ipv4_address"`
		IPAddress     struct {
			ID            int    `json:"id"`
			NetworkID     int    `json:"network_id"`
			IPv4Adress    int    `json:"ipv4_address"`
			CreatedAt     string `json:"created_at"`
			DeletedAt     string `json:"deleted_at"`
			UpdatedAt     string `json:"updated_at"`
			IsDeleted     int    `json:"is_deleted"`
			Network       struct {
				ID          int    `json:"id"`
				UUID        string `json:"uudi"`
				DisplayName string `json:"display_name"`
				IPv4Network int    `json:"ipv4_network"`
				IPv4Prefix  int    `json:"ipv4_prefix"`
				NetworkMode string `json:"network_mode"`
				DomainName  string `json:"domain_named"`
				UpdatedAt   string `json:"updated_at"`
				CreatedAt   string `json:"created_at"`
				DeletedAt   string `json:"deleted_at"`
				IsDeleted   int    `json:"is_deleted"`
				SegmentID   int    `json:"segment_id"`
			} `json:"network"`
		} `json:"ip_adress"`
		InterfaceUUID string `json:"interface_uuid"`
		MacLeaseUUID  string `json:"mac_lease_uuid"`
		NetworkUUID   string `json:"network_uuid"`
	} `json:"ip_leases"`
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

type InterfaceSecuritGroup struct {
	UUID        string
	DisplayName string
	Rules       []string
	Description string
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
