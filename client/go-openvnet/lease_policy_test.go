package openvnet

import "testing"

var lpService = NewLeasePolicyService(testClient())

func TestLeasePolicy(t *testing.T) {
	c := NewClient(nil, nil)

	if c.LeasePolicy == nil {
		t.Errorf("Interface should not be nil")
	}
}

func TestLeasePolicyCreate(t *testing.T) {
	r, _, e := lpService.Create(testLeasePolicy)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(LeasePolicy), r)
}

func TestLeasePolicyGet(t *testing.T) {
	r, _, e := lpService.Get()
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(LeasePolicyList), r)
}

func TestLeasePolicyGetByUUID(t *testing.T) {
	r, _, e := lpService.GetByUUID(testLeasePolicy.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(LeasePolicy), r)
}

func TestLeasePolicyDelete(t *testing.T) {
	_, e := lpService.Delete(testLeasePolicy.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}
}
