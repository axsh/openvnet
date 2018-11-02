package openvnet

import "testing"

func TestIpLease(t *testing.T) {
	c := NewClient(nil, nil)

	if c.IpLease == nil {
		t.Errorf("Interface should not be nil")
	}
}
