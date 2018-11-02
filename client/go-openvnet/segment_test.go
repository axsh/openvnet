package openvnet

import "testing"

func TestSegment(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Segment == nil {
		t.Errorf("Segment should not be nil")
	}
}
