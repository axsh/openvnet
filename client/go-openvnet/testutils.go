package openvnet

import (
	"io"
	"log"
	"reflect"
	"testing"

	"github.com/dghubble/sling"
)

func testClient() *Client {
	return &Client{sling: sling.New().Base("http://localhost:9090/api/1.0/").Client(nil)}
}

func getFieldValue(i interface{}, fieldName string) reflect.Value {
	valueOfT := reflect.ValueOf(i)
	return valueOfT.Elem().FieldByName(fieldName)
}

func checkType(t *testing.T, expected interface{}, recieved interface{}) {
	typeOfRecieved := reflect.TypeOf(recieved)
	typeOfExpected := reflect.TypeOf(expected)

	if typeOfExpected != typeOfRecieved {
		t.Errorf("Resource %s should be %s", typeOfRecieved.String(), typeOfExpected.String())
	}

}

func checkBody(t *testing.T, body io.ReadCloser) {
	b := make([]byte, 0)
	if _, e := body.Read(b); e != nil && e != io.EOF {
		log.Fatalf("failed to read response body: %v", e)
	}
	defer body.Close()

	if len(b) != 0 {
		t.Errorf("Body should be empty was: %d", len(b))
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

var testLeasePolicy = &LeasePolicyCreateParams{
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
