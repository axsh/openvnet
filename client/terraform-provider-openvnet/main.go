package main

import (
	"github.com/axsh/openvnet/client/terraform-provider-openvnet/openvnet"
	"github.com/hashicorp/terraform/plugin"
)

func main() {
	plugin.Serve(&plugin.ServeOpts{
		ProviderFunc: openvnet.Provider,
	})
}