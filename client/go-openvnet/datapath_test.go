package openvnet

import (
	"testing"
)

func TestDatapath(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Datapath == nil {
		t.Errorf("Datapath should not be nil")
	}
}

func TestCRUDCommands(t *testing.T) {
	data := &DatapathCreateParams{
		DisplayName: "test",
		UUID:        "dp-test",
		NodeId:      "test",
		DPID:        "0000aaaaaaaaaaaa",
	}

	service := NewDatapathService(testClient())
	testCreate(t, data, service)
	testGetByUUID(t, data, service)
	testGet(t, service)
	testDelete(t, data, service)
}

func testCreate(t *testing.T, p *DatapathCreateParams, s *DatapathService) {
	resource, _, e := s.Create(p)

	if e != nil {
		t.Error("error should be nil")
	}

	if resource == nil {
		t.Error("resource should not be nil")
	}
}

func testGet(t *testing.T, s *DatapathService) {
	resources, _, e := s.Get()

	if e != nil {
		t.Error("error should be nil")
	}

	if resources == nil {
		t.Error("resources should not be nil")
	}

	if len(resources.Items) != 1 {
		t.Error("resources.Items should be length 1")
	}
}

func testDelete(t *testing.T, p *DatapathCreateParams, s *DatapathService) {
	_, e := s.Delete(p.UUID)

	if e != nil {
		t.Error("error should be nil")
	}
}

func testGetByUUID(t *testing.T, p *DatapathCreateParams, s *DatapathService) {
	resource, _, e := s.GetByUUID(p.UUID)

	if e != nil {
		t.Error("error should be nil")
	}

	if resource == nil {
		t.Error("resource should not be nil")
	}
}
