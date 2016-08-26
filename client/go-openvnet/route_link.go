package openvnet

type RouteLink struct {
	ID           int    `json:"id"`
	UUID         string `json:"uuid"`
	MacAddressID int    `json:"mac_address_id"`
	CreatedAt    string `json:"created_at"`
	DeletedAt    string `json:"deleted_at"`
	IsDeleted    bool   `json:"is_deleted"`
	MacAddress   string `json:"mac_address"`
}

type RouteLinkService struct {
	client *Client
}

type RouteLinkCreateParams {
	UUID       string `url:"uuid"`
	MacAddress string `url:"mac_address"`
}

func (s *RouteLinkService) Create (params *RouteLinkCreateParms) (*RouteLink, *http.Response, error) {

}

func (s *RouteLinkService) Delete (id string) (*http.Response, error) {

}
