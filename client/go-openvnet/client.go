package openvnet

import (
	"fmt"
	"net/http"
	"net/url"

	"github.com/dghubble/sling"
)

const (
	webapiProtocol = "http"
	webapiUri = "localhost"
	webapiPort = "9090"
	webapiVersion = "1.0"

	defaultURL = webapiProtocol +"://" + webapiUri + ":" + webapiPort +"/api/" + webapiVersion
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

func NewClient(url *url.URL, httpClient *http.Client) *Client {
	baseURL := defaultURL
	if url != nil {
		baseURL = url.String()
	}

	fmt.Println(baseURL)

	s := sling.New().Base(baseURL).Client(httpClient)
	c := &Client{sling: s}
	c.Datapath = &DatapathService{client: c, Namespace: "datapaths"}
	c.Interface = &InterfaceService{client: c, Namespace: "interfaces"}
	c.Network = &NetworkService{client: c, Namespace: "networks"}
	c.Route = &RouteService{client: c, Namespace: "routes"}
	c.RouteLink = &RouteLinkService{client: c, Namespace: "route_links"}
	c.Segment = &SegmentService{client: c, Namespace: "segments"}
	return c
}

type OpenVNetError struct {
	ErrorType string `json:"error"`
	Message   string `json:"message"`
	Code      string `json:"code"`
}

func (e *OpenVNetError) Error() string {
	return fmt.Sprint("ERROR")
}
