package openvnet

import "testing"

func TestMacRagneGroup(t *testing.T) {
	c := NewClient(nil, nil)

	if c.MacRangeGroup == nil {
		t.Errorf("MaRangeGroup should not be nil")
	}
}
