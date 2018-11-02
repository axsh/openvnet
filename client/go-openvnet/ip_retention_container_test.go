package openvnet

import "testing"

func TestIpRetentionContainer(t *testing.T) {
	c := NewClient(nil, nil)

	if c.IpRetentionContainer == nil {
		t.Errorf("Interface should not be nil")
	}
}
