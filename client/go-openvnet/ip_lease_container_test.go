package openvnet

import "testing"

func TestIpLeaseContainer(t *testing.T) {
	c := NewClient(nil, nil)

	if c.IpLeaseContainer == nil {
		t.Errorf("Interface should not be nil")
	}
}
