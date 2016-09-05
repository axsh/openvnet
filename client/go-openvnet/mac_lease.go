package openvnet

type MacLease struct {
	ID           int       `json:"id"`
	UUID         string    `json:"uuid"`
	InterfaceID  int       `json:"interface_id"`
	MacAddressID int       `json:"mac_address_id"`
	CreatedAt    string    `json:"created_at"`
	UpdatedAt    string    `json:"updated_at"`
	DeletedAt    string    `json:"deleted_at"`
	IsDeleted    int       `json:"is_deleted"`
	MacAddress   string    `json:"mac_address"`
	SegmentID    int       `json:"segment_id"`
	IPLeases     []IpLease `json:"ip_leases"`
	InterfaceUUID string   `json:"interface_uuid"`
}
