package openvnet

import "testing"

var rlService = NewRouteLinkService(testClient)
var testRouteLink = &RouteLinkCreateParams{
	UUID: "rl-test",
}

func TestRouteLink(t *testing.T) {
	c := NewClient(nil, nil)

	if c.RouteLink == nil {
		t.Errorf("RouteLink should not be nil")
	}
}

func TestRouteLinkCreate(t *testing.T) {
	r, _, e := rlService.Create(testRouteLink)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(RouteLink), r)
}

func TestRouteLinkGet(t *testing.T) {
	r, _, e := rlService.Get()
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(RouteLinkList), r)
}

func TestRouteLinkGetByUUID(t *testing.T) {
	r, _, e := rlService.GetByUUID(testRouteLink.UUID)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(RouteLink), r)
}

func TestRouteLinkDelete(t *testing.T) {
	_, e := rlService.Delete(testRouteLink.UUID)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}
}
