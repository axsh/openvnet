require 'spec_helper'

describe Vnet::NodeApi::IpRetention do
  before do
    use_mock_event_handler
  end

  describe "destroy" do
    it "success" do
      ip_retention = Fabricate(:ip_retention)
      ip_lease = ip_retention.ip_lease

      ip_lease_count = Vnet::Models::IpLease.count
      ip_address_count = Vnet::Models::IpAddress.count
      ip_retention_count = Vnet::Models::IpRetention.count

      Vnet::NodeApi::IpLease.destroy(ip_lease.canonical_uuid)

      expect(Vnet::Models::IpLease.count).to eq ip_lease_count - 1
      expect(Vnet::Models::IpAddress.count).to eq ip_address_count
      expect(Vnet::Models::IpRetention.count).to eq ip_retention_count - 1

      events = MockEventHandler.handled_events
      expect(events.size).to eq 2

      expect(events[0][:event]).to eq Vnet::Event::IP_RETENTION_EXPIRED_ITEM
      expect(events[0][:options][:id]).to eq ip_lease.ip_retention.id

      expect(events[1][:event]).to eq Vnet::Event::INTERFACE_RELEASED_IPV4_ADDRESS
      expect(events[1][:options][:id]).to eq ip_lease.interface_id
      expect(events[1][:options][:ip_lease_id]).to eq ip_lease.id
    end
  end
end
