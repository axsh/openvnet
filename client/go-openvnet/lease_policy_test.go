package openvnet

import "testing"

var lpService = NewLeasePolicyService(testClient)
var testLeasePolicy = &LeasePolicyCreateParams{
	UUID: "lp-test",
}

func TestLeasePolicy(t *testing.T) {
	c := NewClient(nil, nil)

	if c.LeasePolicy == nil {
		t.Errorf("Interface should not be nil")
	}

	if _, exists := c.LeasePolicy.relationServices["ip_retention_containers"]; !exists {
		t.Errorf("Lease policy should have ip retention containers relations service")
	}

	if _, exists := c.LeasePolicy.relationServices["ip_lease_containers"]; !exists {
		t.Errorf("Lease policy should have ip lease containers relations service")
	}

	if _, exists := c.LeasePolicy.relationServices["networks"]; !exists {
		t.Errorf("Lease policy should have network relations service")
	}

	if _, exists := c.LeasePolicy.relationServices["interfaces"]; !exists {
		t.Errorf("Lease policy should have interfaces relations service")
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

func TestLeasePolicyCreateRelation(t *testing.T) {
	var r interface{}
	var e error
	for k, s := range lpService.relationServices {
		if k == "networks" {
			r, _, e = lpService.CreateRelation(k, &LeasePolicyRelationCreateParams{
				IpRangeGroupUUID: "test_id",
			}, testLeasePolicy.UUID, "test_id")
		} else {
			r, _, e = lpService.CreateRelation(k, &LeasePolicyRelationCreateParams{},
				testLeasePolicy.UUID, "test_id")
		}

		if e != nil {
			t.Errorf("Error should be nil")
		}

		checkType(t, s.resource, r)
	}
}

func TestLeasePolicyDeleteRelation(t *testing.T) {
	for k := range lpService.relationServices {
		_, e := lpService.DeleteRelation(k, testLeasePolicy.UUID, "test_id")
		if e != nil {
			t.Errorf("Error should be nil")
		}
	}
}

func TestLeasePolicyGetRelation(t *testing.T) {
	for k, s := range lpService.relationServices {
		r, _, e := lpService.GetRelations(k, testLeasePolicy.UUID)
		if e != nil {
			t.Errorf("Error should be nil")
		}

		checkType(t, s.resourceList, r)
	}
}
