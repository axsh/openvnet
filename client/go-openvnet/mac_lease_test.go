package openvnet

import "testing"

var mlService = NewMacLeaseService(testClient)
var testMacLease = &MacLeaseCreateParams{
	UUID:          "ml-test",
	InterfaceUUID: testInterface.UUID,
	MacAddress:    "00:00:00:00:00:01",
}

func TestMacLease(t *testing.T) {
	c := NewClient(nil, nil)

	if c.MacLease == nil {
		t.Errorf("Interface should not be nil")
	}
}

func TestMacLeaseCreate(t *testing.T) {
	r, _, e := mlService.Create(testMacLease)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(MacLease), r)
}

func TestMacLeaseGet(t *testing.T) {
	r, _, e := mlService.Get()
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(MacLeaseList), r)
}

func TestMacLeaseGetByUUID(t *testing.T) {
	r, _, e := mlService.GetByUUID(testMacLease.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(MacLease), r)
}

func TestMacLeaseDelete(t *testing.T) {
	_, e := mlService.Delete(testMacLease.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}
}
