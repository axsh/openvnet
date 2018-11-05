package openvnet

import (
	"testing"
)

func TestFilter(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Filter == nil {
		t.Errorf("Interface should not be nil")
	}
}
