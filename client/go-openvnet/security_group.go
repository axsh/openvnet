package openvnet

type SecurityGroup struct {
	UUID        string
	DisplayName string
	Rules       []string
	Description string
}
