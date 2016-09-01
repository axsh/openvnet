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
//	Interface *InterfaceService
	Route     *RouteService
	RouteLink *RouteLinkService
	Segment   *SegmentService
}

func (c *Client) post (namespace string, output interface{}, params interface{}) (*http.Response, error) {
	ovnError := new(OpenVNetError)
	resp, err := c.sling.New().Post(namespace).BodyForm(params).Receive(output, ovnError)

	return resp, err
}

func (c *Client) del (id string) (*http.Response, error) {
	ovnError := new(OpenVNetError)
	resp, err := c.sling.New().Delete(id).Receive(nil, ovnError)

	return resp, err
}

func NewClient(url *url.URL, httpClient *http.Client) *Client {
	baseURL := defaultURL
	if url != nil {
		baseURL = url.String()
	}

	fmt.Println(baseURL)

	s := sling.New().Base(baseURL).Client(httpClient)
	c := &Client{sling: s}
	c.Datapath = &DatapathService{client: c}
//	c.Interface = &InterfaceService{client: c}
	c.Network = &NetworkService{client: c}
	c.Route = &RouteService{client: c}
	c.RouteLink = &RouteLinkService{client: c}
	c.Segment = &SegmentService{client: c}
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
