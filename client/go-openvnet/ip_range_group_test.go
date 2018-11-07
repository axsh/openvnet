package openvnet

import "testing"

var iprgService = NewIpRangeGroupService(testClient)
var testIpRangeGroup = &IpRangeGroupCreateParams{
	UUID: "iprg-test",
}

func TestIpRangeGroup(t *testing.T) {
	c := NewClient(nil, nil)

	if c.IpRangeGroup == nil {
		t.Errorf("Interface should not be nil")
	}
}

func TestIpRangeGroupCreate(t *testing.T) {
	r, _, e := iprgService.Create(testIpRangeGroup)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(IpRangeGroup), r)
}

func TestIpRangeGroupGet(t *testing.T) {
	r, _, e := iprgService.Get()
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(IpRangeGroupList), r)
}

func TestIpRangeGroupGetByUUID(t *testing.T) {
	r, _, e := iprgService.GetByUUID(testIpRangeGroup.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(IpRangeGroup), r)
}

func TestIpRangeGroupDelete(t *testing.T) {
	_, e := iprgService.Delete(testIpRangeGroup.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}
}
