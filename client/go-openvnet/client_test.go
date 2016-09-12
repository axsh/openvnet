package openvnet

import "testing"

func TestNewClient (t *testing.T) {
	c := NewClient(nil, nil)

	if c == nil {
		t.Errorf("NewClient() failed")
	}
}
