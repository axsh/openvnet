package openvnet

import "testing"

var ifService = NewInterfaceService(testClient())

func TestInterface(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Interface == nil {
		t.Errorf("Interface should not be nil")
	}
}

func TestInterfaceCreate(t *testing.T) {
	r, _, e := ifService.Create(testInterface)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(Interface), r)
}

func TestInterfaceGet(t *testing.T) {
	r, _, e := ifService.Get()
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(InterfaceList), r)
}

func TestInterfaceGetByUUID(t *testing.T) {
	r, _, e := ifService.GetByUUID(testInterface.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(Interface), r)
}

func TestInterfaceDelete(t *testing.T) {
	_, e := ifService.Delete(testInterface.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}
}
