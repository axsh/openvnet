package openvnet

import "testing"

var segService = NewSegmentService(testClient)
var testSegment = &SegmentCreateParams{
	UUID: "seg-test",
	Mode: "virtual",
}

func TestSegment(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Segment == nil {
		t.Errorf("Segment should not be nil")
	}
}

func TestSegmentCreate(t *testing.T) {
	r, _, e := segService.Create(testSegment)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(Segment), r)
}

func TestSegmentGet(t *testing.T) {
	r, _, e := segService.Get()
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(SegmentList), r)
}

func TestSegmentGetByUUID(t *testing.T) {
	r, _, e := segService.GetByUUID(testSegment.UUID)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(Segment), r)
}

func TestSegmentDelete(t *testing.T) {
	_, e := segService.Delete(testSegment.UUID)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}
}
