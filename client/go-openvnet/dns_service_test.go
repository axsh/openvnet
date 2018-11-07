package openvnet

import "testing"

var dnssService = NewDnsServicesService(testClient)
var testDnsServices = &DnsServicesCreateParams{
	UUID:               "dnss-test",
	NetworkServiceUUID: testNetworkServices.UUID,
}

func TestDnsServices(t *testing.T) {
	c := NewClient(nil, nil)

	if c.DnsServices == nil {
		t.Errorf("MaRangeGroup should not be nil")
	}
}

func TestDnsServicesCreate(t *testing.T) {
	r, _, e := dnssService.Create(testDnsServices)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(DnsServices), r)
}

func TestDnsServicesGet(t *testing.T) {
	r, _, e := dnssService.Get()
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(DnsServicesList), r)
}

func TestDnsServicesGetByUUID(t *testing.T) {
	r, _, e := dnssService.GetByUUID(testDnsServices.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(DnsServices), r)
}

func TestDnsServicesDelete(t *testing.T) {
	_, e := dnssService.Delete(testDnsServices.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}
}
