package openvnet

import "testing"

func TestLeasePolicy(t *testing.T) {
	c := NewClient(nil, nil)

	if c.LeasePolicy == nil {
		t.Errorf("Interface should not be nil")
	}
}
