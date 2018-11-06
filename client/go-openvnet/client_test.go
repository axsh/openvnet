package openvnet

import (
	"os"
	"testing"
)

type testableService struct {
	service *BaseService
	data    interface{}
}

var apiResources = map[string][]string{}
var serviceTable []testableService
var client *Client

func TestNewClient(t *testing.T) {
	c := NewClient(nil, nil)

	if c == nil {
		t.Errorf("NewClient() failed")
	}
}

func TestCreate(t *testing.T) {
	for _, i := range serviceTable {
		testCreate(t, i.service, i.data)
	}
}

func TestGetByUUID(t *testing.T) {
	for _, i := range serviceTable {
		testGetByUUID(t, i.service, getFieldValue(i.data, "UUID").String())
	}
}

func TestGet(t *testing.T) {
	for _, i := range serviceTable {
		testGet(t, i.service)
	}
}

func TestDelete(t *testing.T) {
	// reverse the array here as deleting the base resources which another depends
	// depends on automatically sets the depending resource to deleted, which
	// causes failure
	s := serviceTable
	for i, j := 0, len(s)-1; i < j; i, j = i+1, j-1 {
		s[i], s[j] = s[j], s[i]
	}

	for _, i := range s {
		testDelete(t, i.service, getFieldValue(i.data, "UUID").String())
	}
}

func TestMain(m *testing.M) {
	client = testClient()
	// order is important here as some resources depends on other resources and
	// will use their as the value for the required parameters
	serviceTable = []testableService{
		testableService{NewDatapathService(client).BaseService, testDatapath},
		testableService{NewNetworkService(client).BaseService, testNetwork},
		testableService{NewInterfaceService(client).BaseService, testInterface},
		testableService{NewFilterService(client).BaseService, testFilter},
		testableService{NewIpLeaseService(client).BaseService, testIpLease},
		testableService{NewIpLeaseContainerService(client).BaseService, testIpLeaseContainer},
		testableService{NewIpRangeGroupService(client).BaseService, testIpRangeGroup},
		testableService{NewIpRetentionContainerService(client).BaseService, testIpRetentionContainer},
		testableService{NewLeasePolicyService(client).BaseService, testLeasePoilcy},
		testableService{NewMacRangeGroupService(client).BaseService, testMacRangeGroup},
		testableService{NewMacLeaseService(client).BaseService, testMacLease},
		testableService{NewRouteLinkService(client).BaseService, testRouteLink},
		testableService{NewRouteService(client).BaseService, testRoute},
		testableService{NewSegmentService(client).BaseService, testSegment},
		testableService{NewTopologyService(client).BaseService, testTopology},
		testableService{NewTranslationService(client).BaseService, testTranslation},
	}

	os.Exit(m.Run())
}
