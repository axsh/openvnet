package openvnet

import (
	"testing"
)

var dpService = NewDatapathService(testClient)
var testDatapath = &DatapathCreateParams{
	DisplayName: "test",
	UUID:        "dp-test",
	NodeId:      "test",
	DPID:        "0000aaaaaaaaaaaa",
}

func TestDatapath(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Datapath == nil {
		t.Errorf("Datapath should not be nil")
	}
}

func TestDatapathCreate(t *testing.T) {
	r, _, e := dpService.Create(testDatapath)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(Datapath), r)
}

func TestDatapathGet(t *testing.T) {
	r, _, e := dpService.Get()
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(DatapathList), r)
}

func TestDatapathGetByUUID(t *testing.T) {
	r, _, e := dpService.GetByUUID(testDatapath.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(Datapath), r)
}

func TestDatapathDelete(t *testing.T) {
	_, e := dpService.Delete(testDatapath.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}
}
