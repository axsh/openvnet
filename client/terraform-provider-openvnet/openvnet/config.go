package openvnet

import (
	"github.com/axsh/openvnet/client/go-openvnet"
	"net/url"
)

type Config struct {
	APIEndpoint string
}

func (c *Config) Client() (*openvnet.Client, error) {

	baseURL, err := url.Parse(c.APIEndpoint)
	if err != nil {
		return nil, err
	}
	client := openvnet.NewClient(baseURL, nil)

	return client, err
}
