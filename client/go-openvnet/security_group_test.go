package openvnet

import "testing"

func TestSecurityGroup(t *testing.T) {
	c := NewClient(nil, nil)

	if c.SecurityGroup == nil {
		t.Errorf("SecurityGroup should not be nil")
	}
}
