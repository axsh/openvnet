package openvnet

import (
	"testing"
)

var ilService = NewIpLeaseService(testClient)
var testIpLease = &IpLeaseCreateParams{
	UUID:        "il-test",
	NetworkUUID: testNetwork.UUID,
	Ipv4Address: testNetwork.Ipv4Network,
}

func TestIpLease(t *testing.T) {
	c := NewClient(nil, nil)

	if c.IpLease == nil {
		t.Errorf("Interface should not be nil")
	}
}

func TestIpLeaseCreate(t *testing.T) {
	r, _, e := ilService.Create(testIpLease)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(IpLease), r)
}

func TestIpLeaseGet(t *testing.T) {
	r, _, e := ilService.Get()
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(IpLeaseList), r)
}

func TestIpLeaseGetByUUID(t *testing.T) {
	r, _, e := ilService.GetByUUID(testIpLease.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(IpLease), r)
}

func TestIpLeaseDelete(t *testing.T) {
	_, e := ilService.Delete(testIpLease.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}
}
