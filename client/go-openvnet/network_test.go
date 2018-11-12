package openvnet

import "testing"

var nwService = NewNetworkService(testClient)
var testNetwork = &NetworkCreateParams{
	UUID:        "nw-test",
	Ipv4Network: "10.0.100.0",
	Ipv4Prefix:  24,
	Mode:        "virtual",
}

func TestNetwork(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Network == nil {
		t.Errorf("Network should not be nil")
	}
}

func TestNetworkCreate(t *testing.T) {
	r, _, e := nwService.Create(testNetwork)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(Network), r)
}

func TestNetworkGet(t *testing.T) {
	r, _, e := nwService.Get()
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(NetworkList), r)
}

func TestNetworkGetByUUID(t *testing.T) {
	r, _, e := nwService.GetByUUID(testNetwork.UUID)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(Network), r)
}

func TestNetworkDelete(t *testing.T) {
	_, e := nwService.Delete(testNetwork.UUID)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}
}
