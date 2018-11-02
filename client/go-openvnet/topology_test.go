package openvnet

import "testing"

func TestTopology(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Topology == nil {
		t.Errorf("Interface should not be nil")
	}
}
