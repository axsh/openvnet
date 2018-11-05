package openvnet

import (
	"testing"

	"github.com/dghubble/sling"
)

func testClient() *Client {
	return &Client{sling: sling.New().Base("http://192.168.21.100:9090/api/1.0/").Client(nil)}
}

func testCreate(t *testing.T, s *BaseService, data interface{}) {
	r, _, e := s.Create(data)

	if e != nil {
		t.Error("error sohuld be nil")
	}

	if r == nil {
		t.Error("resource should not be nil")
	}
}

func testGet(t *testing.T, s *BaseService) {
	resources, _, e := s.Get()

	if e != nil {
		t.Error("error should be nil")
	}

	if resources == nil {
		t.Error("resources should not be nil")
	}
}

func testDelete(t *testing.T, s *BaseService, data string) {
	_, e := s.Delete(data)

	if e != nil {
		t.Error("error should be nil")
	}
}

func testGetByUUID(t *testing.T, s *BaseService, data string) {
	resource, _, e := s.GetByUUID(data)

	if e != nil {
		t.Error("error should be nil")
	}

	if resource == nil {
		t.Error("resource should not nil")
	}
}

// test datasets

var testDatapath = &DatapathCreateParams{
	DisplayName: "test",
	UUID:        "dp-test",
	NodeId:      "test",
	DPID:        "0000aaaaaaaaaaaa",
}

var testFilter = &FilterCreateParams{
	UUID:          "fil-test",
	InterfaceUUID: testInterface.UUID,
	Mode:          "static",
}

var testInterface = &InterfaceCreateParams{
	UUID: "if-test",
	Mode: "vif",
}

var testIpLease = &IpLeaseCreateParams{
	UUID:        "il-test",
	NetworkUUID: testNetwork.UUID,
	Ipv4Address: testNetwork.Ipv4Network,
}

var testIpLeaseContainer = &IpLeaseContainerCreateParams{
	UUID: "ilc-test",
}

var testIpRangeGroupContainer = &IpRangeGroupCreateParams{
	UUID: "iprg-test",
}

var testIpRetentionContainer = &IpRetentionCreateParams{
	UUID: "irc-test",
}

var testLeasePoilcy = &LeasePolicyCreateParams{
	UUID: "lp-test",
}

var testMacRangeGroupContainer = &MacRangeGroupCreateParams{
	UUID: "mrg-test",
}

var testMacLease = &MacLeaseCreateParams{
	UUID: "ml-test",
}

var testNetwork = &NetworkCreateParams{
	UUID:        "nw-test",
	Ipv4Network: "10.0.100.0",
	Ipv4Prefix:  24,
	Mode:        "vif",
}

var testRoute = &RouteCreateParams{
	UUID: "r-test",
}

var testRouteLink = &RouteLinkCreateParams{
	UUID: "rl-test",
}

var testSegment = &SegmentCreateParams{
	UUID: "seg-test",
}

var testTopology = &TopologyCreateParams{
	UUID: "topo-test",
}

var testTranslation = &TranslationCreateParams{
	UUID: "tl-test",
}
