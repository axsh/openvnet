package openvnet

import "testing"

func TestTranslation(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Translation == nil {
		t.Errorf("Segment should not be nil")
	}
}
