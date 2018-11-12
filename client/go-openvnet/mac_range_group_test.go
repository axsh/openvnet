package openvnet

import "testing"

var mrgService = NewMacRangeGroupService(testClient)
var testMacRangeGroup = &MacRangeGroupCreateParams{
	UUID: "mrg-test",
}

func TestMacRagneGroup(t *testing.T) {
	c := NewClient(nil, nil)

	if c.MacRangeGroup == nil {
		t.Errorf("MaRangeGroup should not be nil")
	}
}

func TestMacRangeGroupCreate(t *testing.T) {
	r, _, e := mrgService.Create(testMacRangeGroup)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(MacRangeGroup), r)
}

func TestMacRangeGroupGet(t *testing.T) {
	r, _, e := mrgService.Get()
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(MacRangeGroupList), r)
}

func TestMacRangeGroupGetByUUID(t *testing.T) {
	r, _, e := mrgService.GetByUUID(testMacRangeGroup.UUID)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(MacRangeGroup), r)
}

func TestMacRangeGroupDelete(t *testing.T) {
	_, e := mrgService.Delete(testMacRangeGroup.UUID)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}
}
