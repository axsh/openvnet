package openvnet

import "testing"

var nwService = NewNetworkService(testClient())

func TestNetwork(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Network == nil {
		t.Errorf("Network should not be nil")
	}
}

func TestNetworkCreate(t *testing.T) {
	r, _, e := nwService.Create(testNetwork)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(Network), r)
}

func TestNetworkGet(t *testing.T) {
	r, _, e := nwService.Get()
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(NetworkList), r)
}

func TestNetworkGetByUUID(t *testing.T) {
	r, _, e := nwService.GetByUUID(testNetwork.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(Network), r)
}

func TestNetworkDelete(t *testing.T) {
	_, e := nwService.Delete(testNetwork.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}
}
