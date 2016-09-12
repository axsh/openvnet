package openvnet

import "testing"

func TestRouteLink(t *testing.T) {
	c := NewClient(nil, nil)

	if c.RouteLink == nil {
		t.Errorf("RouteLink should not be nil")
	}
}
