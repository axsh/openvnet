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
var testDatapathRelation = &DatapathRelationCreateParams{
	InterfaceUUID: testInterface.UUID,
	MacAddress:    "00:00:10:10:10:10",
}

func TestDatapath(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Datapath == nil {
		t.Errorf("Datapath should not be nil")
	}

	if _, exists := c.Datapath.relationServices["route_links"]; !exists {
		t.Errorf("Datapath should have route links relations service")
	}

	if _, exists := c.Datapath.relationServices["segments"]; !exists {
		t.Errorf("Datapath should have segments relations service")
	}

	if _, exists := c.Datapath.relationServices["networks"]; !exists {
		t.Errorf("Datapath should have network relations service")
	}
}

func TestDatapathCreate(t *testing.T) {
	r, _, e := dpService.Create(testDatapath)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(Datapath), r)
}

func TestDatapathGet(t *testing.T) {
	r, _, e := dpService.Get()
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(DatapathList), r)
}

func TestDatapathGetByUUID(t *testing.T) {
	r, _, e := dpService.GetByUUID(testDatapath.UUID)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(Datapath), r)
}

func TestDatapathDelete(t *testing.T) {
	_, e := dpService.Delete(testDatapath.UUID)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}
}

func TestDatapathCreateRelation(t *testing.T) {
	for k, s := range dpService.relationServices {
		r, _, e := dpService.CreateRelation(k, testDatapathRelation, testDatapath.UUID, "test_id")
		if e != nil {
			t.Errorf("Error should be nil: %v", e)
		}

		checkType(t, s.resource, r)
	}
}

func TestDatapathDeleteRelation(t *testing.T) {
	for k := range dpService.relationServices {
		_, e := dpService.DeleteRelation(k, testDatapath.UUID, "test_id")
		if e != nil {
			t.Errorf("Error should be nil: %v", e)
		}
	}
}

func TestDatapathGetRelation(t *testing.T) {
	for k, s := range dpService.relationServices {
		r, _, e := dpService.GetRelations(k, testDatapath.UUID)
		if e != nil {
			t.Errorf("Error should be nil: %v", e)
		}

		checkType(t, s.resourceList, r)
	}
}
