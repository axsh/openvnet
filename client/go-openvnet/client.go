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
	Translation          *TranslationService
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
	c.Datapath = NewDatapathService(c)
	c.Filter = NewFilterService(c)
	c.Interface = NewInterfaceService(c)
	c.IpLeaseContainer = NewIpLeaseContainerService(c)
	c.IpLease = NewIpLeaseService(c)
	c.IpRangeGroup = NewIpRangeGroupService(c)
	c.IpRetentionContainer = NewIpRetentionContainerService(c)
	c.LeasePolicy = NewLeasePolicyService(c)
	c.MacLease = NewMacLeaseService(c)
	c.MacRangeGroup = NewMacRangeGroupService(c)
	c.Network = NewNetworkService(c)
	c.RouteLink = NewRouteLinkService(c)
	c.Route = NewRouteService(c)
	c.Segment = NewSegmentService(c)
	c.SecurityGroup = NewSecurityGroupService(c)
	c.Topology = NewTopologyService(c)
	c.Translation = NewTranslationService(c)
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
