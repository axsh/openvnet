package openvnet

type IpLease struct {
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
		ID            int     `json:"id"`
		NetworkID     int     `json:"network_id"`
		IPv4Adress    int     `json:"ipv4_address"`
		CreatedAt     string  `json:"created_at"`
		DeletedAt     string  `json:"deleted_at"`
		UpdatedAt     string  `json:"updated_at"`
		IsDeleted     int     `json:"is_deleted"`
		Network       Network `json:"network"`
	} `json:"ip_adress"`
	InterfaceUUID string `json:"interface_uuid"`
	MacLeaseUUID  string `json:"mac_lease_uuid"`
	NetworkUUID   string `json:"network_uuid"`
}
