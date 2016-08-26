package openvnet

import (
	"fmt"
	"net/http"

	"github.com/dghubble/sling"
)

const (
	webapiProtocol = "http"
	webapiUri = "localhost"
	webapiPort = "9101"
	webapiVersion = "1.0"
)

type Client struct {
	sling     *sling.Sling

	Datapath  *DatapathService
	Network   *NetworkService
	Interface *InterfaceService
	Route     *RouteService
	RouteLink *RouteLinkService
	Segment   *SegmentService
}

func NewClient(baseURL *url.URL, httpClient *http.Client) *Client {
	if baseURL == nil {
		baseURL := webapiProtocol +"://" + webapiUri + ":" + webapiPort +"/api/" + webapiVersion
	}

	s = sling.New().Base(baseURL).Client(httpClient)
	c := &Client{sling: s}
	c.Datapath = &DatapathService{client: c}
	c.Interface = &InterfaceService{client: c}
	c.Network = &NetworkService{client: c}
	c.Route = &RouteService{client: c}
	c.RouteLink = &RouteLinkService{client: c}
	c.Segment = &SegmentService{client: c}
	return c
}
