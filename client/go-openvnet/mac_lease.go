package openvnet

type MacLease struct {
	ItemBase
	InterfaceID   int       `json:"interface_id"`
	MacAddressID  int       `json:"mac_address_id"`
	MacAddress    string    `json:"mac_address"`
	SegmentID     int       `json:"segment_id"`
	IPLeases      []IpLease `json:"ip_leases"`
	InterfaceUUID string    `json:"interface_uuid"`
}
