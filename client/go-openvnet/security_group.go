package openvnet

type SecurityGroup struct {
	UUID        string `json:"uudi"`
	DisplayName string `json:"display_name"`
	Rules       string `json:"rules"`
	Description string `json:"description"`
}

