package openvnet

type IpLease struct {
	ItemBase
	InterfaceID   int    `json:"interface_id"`
	MacLeaseID    int    `json:"mac_lease_id"`
	IPAddressID   int    `json:"ip_address_id"`
	EnableRouting bool   `json:"enable_routing"`
	NetworkID     int    `json:"network_id"`
	IPv4Adress    string `json:"ipv4_address"`
	IPAddress     struct {
		ItemBase
		ID         int     `json:"id"`
		NetworkID  int     `json:"network_id"`
		IPv4Adress int     `json:"ipv4_address"`
		Network    Network `json:"network"`
	} `json:"ip_adress"`
	InterfaceUUID string `json:"interface_uuid"`
	MacLeaseUUID  string `json:"mac_lease_uuid"`
	NetworkUUID   string `json:"network_uuid"`
}
