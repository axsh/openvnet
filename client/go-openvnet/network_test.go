package openvnet

import "testing"

func TestNetwork(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Network == nil {
		t.Errorf("Network should not be nil")
	}
}
