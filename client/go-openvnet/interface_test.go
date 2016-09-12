package openvnet

import "testing"

func TestInterface(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Interface == nil {
		t.Errorf("Interface should not be nil")
	}
}
