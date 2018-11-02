package openvnet

import "testing"

func TestIpRangeGroup(t *testing.T) {
	c := NewClient(nil, nil)

	if c.IpRangeGroup == nil {
		t.Errorf("Interface should not be nil")
	}
}
