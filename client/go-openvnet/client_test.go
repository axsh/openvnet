package openvnet

import (
	"testing"
)

var apiResources = map[string][]string{}
var services []BaseService
var client *Client

func TestNewClient(t *testing.T) {
	c := NewClient(nil, nil)

	if c == nil {
		t.Errorf("NewClient() failed")
	}
}

func TestCreate(t *testing.T) {

	testCreate(t, client.Datapath.BaseService, datapath)
	testCreate(t, client.Filter.BaseService, datapath)
	testCreate(t, client.Interface.BaseService, datapath)
	testCreate(t, client.IpLease.BaseService, datapath)
	testCreate(t, client.IpLeaseContainer.BaseService, datapath)
	testCreate(t, client.IpRangeGroup.BaseService, datapath)
	testCreate(t, client.IpRetentionContainer.BaseService, datapath)
	testCreate(t, client.LeasePolicy.BaseService, datapath)
	testCreate(t, client.MacLease.BaseService, datapath)
	testCreate(t, client.MacRangeGroup.BaseService, datapath)
	testCreate(t, client.Network.BaseService, datapath)
	testCreate(t, client.Route.BaseService, datapath)
	testCreate(t, client.RouteLink.BaseService, datapath)
	testCreate(t, client.Segment.BaseService, datapath)
	testCreate(t, client.Topology.BaseService, datapath)
	testCreate(t, client.Translation.BaseService, datapath)
}

func TestGetByUUID(t *testing.T) {
	testGetByUUID(t, client.Datapath.BaseService, datapath)
	testGetByUUID(t, client.Filter.BaseService, datapath)
	testGetByUUID(t, client.Interface.BaseService, datapath)
	testGetByUUID(t, client.IpLease.BaseService, datapath)
	testGetByUUID(t, client.IpLeaseContainer.BaseService, datapath)
	testGetByUUID(t, client.IpRangeGroup.BaseService, datapath)
	testGetByUUID(t, client.IpRetentionContainer.BaseService, datapath)
	testGetByUUID(t, client.LeasePolicy.BaseService, datapath)
	testGetByUUID(t, client.MacLease.BaseService, datapath)
	testGetByUUID(t, client.MacRangeGroup.BaseService, datapath)
	testGetByUUID(t, client.Network.BaseService, datapath)
	testGetByUUID(t, client.Route.BaseService, datapath)
	testGetByUUID(t, client.RouteLink.BaseService, datapath)
	testGetByUUID(t, client.Segment.BaseService, datapath)
	testGetByUUID(t, client.Topology.BaseService, datapath)
	testGetByUUID(t, client.Translation.BaseService, datapath)
}

func TestGet(t *testing.T) {
	testGet(t, client.Datapath.BaseService)
	testGet(t, client.Filter.BaseService)
	testGet(t, client.Interface.BaseService)
	testGet(t, client.IpLease.BaseService)
	testGet(t, client.IpLeaseContainer.BaseService)
	testGet(t, client.IpRangeGroup.BaseService)
	testGet(t, client.IpRetentionContainer.BaseService)
	testGet(t, client.LeasePolicy.BaseService)
	testGet(t, client.MacLease.BaseService)
	testGet(t, client.MacRangeGroup.BaseService)
	testGet(t, client.Network.BaseService)
	testGet(t, client.Route.BaseService)
	testGet(t, client.RouteLink.BaseService)
	testGet(t, client.Segment.BaseService)
	testGet(t, client.Topology.BaseService)
}

func TestDelete(t *testing.T) {
	testDelete(t, client.Datapath.BaseService, datapath)
	testDelete(t, client.Filter.BaseService, datapath)
	testDelete(t, client.Interface.BaseService, datapath)
	testDelete(t, client.IpLease.BaseService, datapath)
	testDelete(t, client.IpLeaseContainer.BaseService, datapath)
	testDelete(t, client.IpRangeGroup.BaseService, datapath)
	testDelete(t, client.IpRetentionContainer.BaseService, datapath)
	testDelete(t, client.LeasePolicy.BaseService, datapath)
	testDelete(t, client.MacLease.BaseService, datapath)
	testDelete(t, client.MacRangeGroup.BaseService, datapath)
	testDelete(t, client.Network.BaseService, datapath)
	testDelete(t, client.Route.BaseService, datapath)
	testDelete(t, client.RouteLink.BaseService, datapath)
	testDelete(t, client.Segment.BaseService, datapath)
	testDelete(t, client.Topology.BaseService, datapath)
	testDelete(t, client.Translation.BaseService, datapath)
}
func TestMain(m *testing.M) {
	client = testClient()

	// os.Exit(m.Run())
}
