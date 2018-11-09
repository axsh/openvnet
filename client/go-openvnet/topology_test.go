package openvnet

import "testing"

var topoService = NewTopologyService(testClient)
var testTopology = &TopologyCreateParams{
	UUID: "topo-test",
	Mode: "simple_underlay",
}

var testTopoDelation = &TopologyRelation{}

func TestTopology(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Topology == nil {
		t.Errorf("Interface should not be nil")
	}

	if _, exists := c.Topology.relationServices["segments"]; !exists {
		t.Errorf("Topology should have segments relations service")
	}

	if _, exists := c.Topology.relationServices["datapaths"]; !exists {
		t.Errorf("Topology should have datapaths relations service")
	}

	if _, exists := c.Topology.relationServices["route_links"]; !exists {
		t.Errorf("Topology should have route links relations service")
	}

	if _, exists := c.Topology.relationServices["networks"]; !exists {
		t.Errorf("Topology should have network relations service")
	}

	if _, exists := c.Topology.relationServices["underlays"]; !exists {
		t.Errorf("Topology should have underlays relations service")
	}
}

func TestTopologyCreate(t *testing.T) {
	r, _, e := topoService.Create(testTopology)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(Topology), r)
}

func TestTopologyGet(t *testing.T) {
	r, _, e := topoService.Get()
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(TopologyList), r)
}

func TestTopologyGetByUUID(t *testing.T) {
	r, _, e := topoService.GetByUUID(testTopology.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(Topology), r)
}

func TestTopologyDelete(t *testing.T) {
	_, e := topoService.Delete(testTopology.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}
}

func TestTopologyCreateRelation(t *testing.T) {
	for k, s := range topoService.relationServices {
		r, _, e := topoService.CreateRelation(k, nil, testTopology.UUID, "test_id")
		if e != nil {
			t.Errorf("Error should be nil")
		}

		checkType(t, s.resource, r)
	}

}

func TestTopologyDeleteRelation(t *testing.T) {
	for k := range topoService.relationServices {
		_, e := topoService.DeleteRelation(k, testTopology.UUID, "test_id")
		if e != nil {
			t.Errorf("Error should be nil")
		}
	}
}

func TestTopologyGetRelation(t *testing.T) {
	for k, s := range topoService.relationServices {
		r, _, e := topoService.GetRelations(k, testTopology.UUID)
		if e != nil {
			t.Errorf("Error should be nil")
		}

		checkType(t, s.resourceList, r)
	}
}
