package openvnet

import "testing"

var rService = NewRouteService(testClient)
var testRoute = &RouteCreateParams{
	UUID:          "r-test",
	RouteLinkUUID: testRouteLink.UUID,
	InterfaceUUID: testInterface.UUID,
	NetworkUUID:   testNetwork.UUID,
	Ipv4Network:   testNetwork.Ipv4Network,
}

func TestRoute(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Route == nil {
		t.Errorf("Route should not be nil")
	}
}

func TestRouteCreate(t *testing.T) {
	r, _, e := rService.Create(testRoute)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(Route), r)
}

func TestRouteGet(t *testing.T) {
	r, _, e := rService.Get()
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(RouteList), r)
}

func TestRouteGetByUUID(t *testing.T) {
	r, _, e := rService.GetByUUID(testRoute.UUID)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}

	checkType(t, new(Route), r)
}

func TestRouteDelete(t *testing.T) {
	_, e := rService.Delete(testRoute.UUID)
	if e != nil {
		t.Errorf("Error should be nil: %v", e)
	}
}
