package openvnet

import "testing"

func TestMacLease(t *testing.T) {
	c := NewClient(nil, nil)

	if c.MacLease == nil {
		t.Errorf("Interface should not be nil")
	}
}
