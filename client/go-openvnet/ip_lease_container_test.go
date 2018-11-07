package openvnet

import "testing"

var ilcService = NewIpLeaseContainerService(testClient)
var testIpLeaseContainer = &IpLeaseContainerCreateParams{
	UUID: "ilc-test",
}

func TestIpLeaseContainer(t *testing.T) {
	c := NewClient(nil, nil)

	if c.IpLeaseContainer == nil {
		t.Errorf("IpLeaseContainer should not be nil")
	}
}

func TestIpLeaseContainerCreate(t *testing.T) {
	r, _, e := ilcService.Create(testIpLeaseContainer)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(IpLeaseContainer), r)
}

func TestIpLeaseContainerGet(t *testing.T) {
	r, _, e := ilcService.Get()
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(IpLeaseContainerList), r)
}

func TestIpLeaseContainerGetByUUID(t *testing.T) {
	r, _, e := ilcService.GetByUUID(testIpLeaseContainer.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(IpLeaseContainer), r)
}

func TestIpLeaseContainerDelete(t *testing.T) {
	_, e := ilcService.Delete(testIpLeaseContainer.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}
}
