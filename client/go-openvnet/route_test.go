package openvnet

import "testing"

func TestRoute(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Route == nil {
		t.Errorf("Route should not be nil")
	}
}
