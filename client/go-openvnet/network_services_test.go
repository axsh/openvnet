package openvnet

import "testing"

var nsService = NewNetworkServicesService(testClient)
var testNetworkServices = &NetworkServicesCreateParams{
	UUID: "ns-test",
	Mode: "dns",
}

func TestNetworkServices(t *testing.T) {
	c := NewClient(nil, nil)

	if c.NetworkServices == nil {
		t.Errorf("MaRangeGroup should not be nil")
	}
}

func TestNetworkServicesCreate(t *testing.T) {
	r, _, e := nsService.Create(testNetworkServices)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(NetworkServices), r)
}

func TestNetworkServicesGet(t *testing.T) {
	r, _, e := nsService.Get()
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(NetworkServicesList), r)
}

func TestNetworkServicesGetByUUID(t *testing.T) {
	r, _, e := nsService.GetByUUID(testNetworkServices.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(NetworkServices), r)
}

func TestNetworkServicesDelete(t *testing.T) {
	_, e := nsService.Delete(testNetworkServices.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}
}
