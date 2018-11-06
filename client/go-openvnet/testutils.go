package openvnet

import (
	"reflect"
	"testing"

	"github.com/dghubble/sling"
)

func testClient() *Client {
	return &Client{sling: sling.New().Base("http://192.168.21.100:9090/api/1.0/").Client(nil)}
}

func getFieldValue(i interface{}, fieldName string) reflect.Value {
	valueOfT := reflect.ValueOf(i)
	return valueOfT.Elem().FieldByName(fieldName)
}

func testCreate(t *testing.T, s *BaseService, data interface{}) {
	r, _, e := s.Create(data)

	if e != nil {
		t.Errorf("%v.Create() error sohuld be nil: %v", s, e)
	}

	if r == nil {
		t.Errorf("%v.Create() resource: %v should not be nil", s, r)
	}
}

func testGet(t *testing.T, s *BaseService) {
	r, _, e := s.Get()

	if e != nil {
		t.Errorf("%v.Get() error should be nil: %v", s, e)
	}

	if r == nil {
		t.Errorf("%v.Get() resources: %v should not be nil", s, r)
	}
}

func testDelete(t *testing.T, s *BaseService, data string) {
	_, e := s.Delete(data)

	if e != nil {
		t.Errorf("%v.Delete() error should be nil: %v", s, e)
	}
}

func testGetByUUID(t *testing.T, s *BaseService, data string) {
	r, _, e := s.GetByUUID(data)

	if e != nil {
		t.Errorf("%v.GetByUUID() error should be nil: %v", s, e)
	}

	if r == nil {
		t.Errorf("%v.GetByUUDI() resource: %v should not nil", s, r)
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

var testIpRangeGroup = &IpRangeGroupCreateParams{
	UUID: "iprg-test",
}

var testIpRetentionContainer = &IpRetentionContainerCreateParams{
	UUID: "irc-test",
}

var testLeasePoilcy = &LeasePolicyCreateParams{
	UUID: "lp-test",
}

var testMacRangeGroup = &MacRangeGroupCreateParams{
	UUID: "mrg-test",
}

var testMacLease = &MacLeaseCreateParams{
	UUID:          "ml-test",
	InterfaceUUID: testInterface.UUID,
	MacAddress:    "00:00:00:00:00:01",
}

var testNetwork = &NetworkCreateParams{
	UUID:        "nw-test",
	Ipv4Network: "10.0.100.0",
	Ipv4Prefix:  24,
	Mode:        "virtual",
}

var testRoute = &RouteCreateParams{
	UUID:          "r-test",
	RouteLinkUUID: testRouteLink.UUID,
	InterfaceUUID: testInterface.UUID,
	NetworkUUID:   testNetwork.UUID,
	Ipv4Network:   testNetwork.Ipv4Network,
}

var testRouteLink = &RouteLinkCreateParams{
	UUID: "rl-test",
}

var testSegment = &SegmentCreateParams{
	UUID: "seg-test",
	Mode: "virtual",
}

var testTopology = &TopologyCreateParams{
	UUID: "topo-test",
	Mode: "simple_underlay",
}

var testTranslation = &TranslationCreateParams{
	UUID:          "tr-test",
	InterfaceUUID: testInterface.UUID,
	Mode:          "static_address",
}
