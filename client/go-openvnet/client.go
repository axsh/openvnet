package openvnet

import (
	"fmt"
	"net/http"
	"net/url"

	"github.com/dghubble/sling"
)

const (
	webapiProtocol = "http"
	webapiUri      = "localhost"
	webapiPort     = "9090"
	webapiVersion  = "1.0"

	defaultURL = webapiProtocol + "://" + webapiUri + ":" + webapiPort + "/api/" + webapiVersion
)

type Client struct {
	sling *sling.Sling

	Datapath             *DatapathService
	Filter               *FilterService
	Interface            *InterfaceService
	IpLeaseContainer     *IpLeaseContainerService
	IpLease              *IpLeaseService
	IpRangeGroup         *IpRangeGroupService
	IpRetentionContainer *IpRetentionContainerService
	LeasePolicy          *LeasePolicyService
	MacLease             *MacLeaseService
	MacRangeGroup        *MacRangeGroupService
	Network              *NetworkService
	Route                *RouteService
	RouteLink            *RouteLinkService
	SecurityGroup        *SecurityGroupService
	Segment              *SegmentService
	Topology             *TopologyService
}

func (c *Client) post(uri string, output interface{}, params interface{}) (*http.Response, error) {
	ovnError := new(OpenVNetError)
	resp, err := c.sling.New().Post(uri).BodyForm(params).Receive(output, ovnError)

	return checkError(ovnError, resp, err)
}

func (c *Client) put(uri string, output interface{}, params interface{}) (*http.Response, error) {
	ovnError := new(OpenVNetError)
	resp, err := c.sling.New().Put(uri).BodyForm(params).Receive(output, ovnError)

	return checkError(ovnError, resp, err)
}

func (c *Client) del(uri string) (*http.Response, error) {
	ovnError := new(OpenVNetError)
	resp, err := c.sling.New().Delete(uri).Receive(nil, ovnError)

	return checkError(ovnError, resp, err)
}

func (c *Client) get(uri string, output interface{}) (*http.Response, error) {
	ovnError := new(OpenVNetError)
	resp, err := c.sling.New().Get(uri).Receive(output, ovnError)

	return checkError(ovnError, resp, err)
}

func NewClient(url *url.URL, httpClient *http.Client) *Client {
	baseURL := defaultURL
	if url != nil {
		baseURL = url.String()
	}

	s := sling.New().Base(baseURL).Client(httpClient)
	c := &Client{sling: s}
	c.Datapath = &DatapathService{client: c}
	c.Filter = &FilterService{client: c}
	c.Interface = &InterfaceService{client: c}
	c.IpLeaseContainer = &IpLeaseContainerService{client: c}
	c.IpLease = &IpLeaseService{client: c}
	c.IpRangeGroup = &IpRangeGroupService{client: c}
	c.IpRetentionContainer = &IpRetentionContainerService{client: c}
	c.LeasePolicy = &LeasePolicyService{client: c}
	c.MacLease = &MacLeaseService{client: c}
	c.MacRangeGroup = &MacRangeGroupService{client: c}
	c.Network = &NetworkService{client: c}
	c.RouteLink = &RouteLinkService{client: c}
	c.Route = &RouteService{client: c}
	c.Segment = &SegmentService{client: c}
	c.SecurityGroup = &SecurityGroupService{client: c}
	c.Topology = &TopologyService{client: c}
	return c
}

type OpenVNetError struct {
	ErrorType string `json:"error"`
	Message   string `json:"message"`
	Code      string `json:"code"`
}

func (e *OpenVNetError) Error() string {
	return fmt.Sprintf("%s\nMessage: %s\nCode: %s",
		e.ErrorType, e.Message, e.Code)
}

func checkError(ovnError *OpenVNetError, resp *http.Response, err error) (*http.Response, error) {
	if err == nil {
		if resp.StatusCode >= 400 {
			err = ovnError
			fmt.Println(err)
		}
	}
	return resp, err
}
