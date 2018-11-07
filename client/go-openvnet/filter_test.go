package openvnet

import (
	"testing"
)

var filService = NewFilterService(testClient)
var testFilter = &FilterCreateParams{
	UUID:          "fil-test",
	InterfaceUUID: testInterface.UUID,
	Mode:          "static",
}

func TestFilter(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Filter == nil {
		t.Errorf("Interface should not be nil")
	}
}

func TestFilterCreate(t *testing.T) {
	r, _, e := filService.Create(testFilter)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(Filter), r)
}

func TestFilterGet(t *testing.T) {
	r, _, e := filService.Get()
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(FilterList), r)
}

func TestFilterGetByUUID(t *testing.T) {
	r, _, e := filService.GetByUUID(testFilter.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(Filter), r)
}

func TestFilterDelete(t *testing.T) {
	_, e := filService.Delete(testFilter.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}
}
