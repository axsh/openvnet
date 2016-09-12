package openvnet

import "testing"

func TestDatapath(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Datapath == nil {
		t.Errorf("Datapath should not be nil")
	}
}
