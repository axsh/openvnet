package openvnet

import "testing"

var topoService = NewTopologyService(testClient)
var testTopology = &TopologyCreateParams{
	UUID: "topo-test",
	Mode: "simple_underlay",
}

func TestTopology(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Topology == nil {
		t.Errorf("Interface should not be nil")
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
