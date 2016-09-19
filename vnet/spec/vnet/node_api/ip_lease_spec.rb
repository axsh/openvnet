# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }

describe Vnet::NodeApi::IpLease do
  before(:each) { use_mock_event_handler }

  let(:events) { MockEventHandler.handled_events }

  describe "create" do
    it "success" do
      network = Fabricate(:network)
      ipv4_address = random_ipv4_i
      interface = Fabricate(:interface)
      mac_lease = Fabricate(:mac_lease, interface: interface)

      now = Time.now
      allow(Time).to receive(:now).and_return(now)

      ip_lease = Vnet::NodeApi::IpLease.execute(
        :create,
        mac_lease: mac_lease,
        network_id: network.id,
        ipv4_address: ipv4_address
      )

      model = Vnet::Models::IpLease[ip_lease[:uuid]]
      expect(model.ip_address.ipv4_address).to eq ipv4_address
      expect(model.network_id).to eq network.id
      expect(ip_lease[:ip_address_id]).to eq model.ip_address_id
      expect(ip_lease[:interface_id]).to eq interface.id

      expect(events.size).to eq 1

      events.first.tap do |event|
        expect(event[:event]).to eq Vnet::Event::INTERFACE_LEASED_IPV4_ADDRESS
        expect(event[:options][:id]).to eq interface.id
        expect(event[:options][:ip_lease_id]).to eq ip_lease[:id]
      end
    end
  end

  describe "destroy" do
    let(:ip_retention_container) {
      Fabricate(:ip_retention_container)
    }
    let(:ip_retention) {
      Fabricate(:ip_retention_with_ip_lease, ip_retention_container: ip_retention_container)
    }

    let(:delete_item) { ip_retention.ip_lease }
    let(:delete_filter) { delete_item.canonical_uuid }
    let(:delete_events) {
      [ [ Vnet::Event::INTERFACE_RELEASED_IPV4_ADDRESS, {
            id: delete_item.interface_id,
            ip_lease_id: delete_item.id
          }],
        [ Vnet::Event::IP_RETENTION_CONTAINER_REMOVED_IP_RETENTION, {
            id: ip_retention.id
          }]]
    }

    include_examples 'delete item on node_api', :ip_lease
  end

  describe "release" do
    it "success" do
      current_time = Time.now
      allow(Time).to receive(:now).and_return(current_time)

      ip_lease = Fabricate(:ip_lease)
      interface = ip_lease.interface
      ip_retention_global = Fabricate(
        :ip_retention,
        ip_retention_container: Fabricate(:ip_retention_container),
        ip_lease: ip_lease,
        leased_at: current_time - 1000
      )
      ip_retention_user = Fabricate(
        :ip_retention,
        ip_retention_container: Fabricate(:ip_retention_container),
        ip_lease: ip_lease,
        leased_at: current_time - 1000
      )

      ip_lease = Vnet::NodeApi::IpLease.release(ip_lease.canonical_uuid)

      expect(ip_lease.interface_id).to be_nil
      expect(ip_lease.mac_lease_id).to be_nil

      expect(events.size).to eq 3

      events.first.tap do |event|
        expect(event[:event]).to eq Vnet::Event::INTERFACE_RELEASED_IPV4_ADDRESS
        expect(event[:options][:id]).to eq interface.id
        expect(event[:options][:ip_lease_id]).to eq ip_lease.id
      end

      events[1].tap do |event|
        expect(event[:event]).to eq Vnet::Event::IP_RETENTION_CONTAINER_ADDED_IP_RETENTION
        expect(event[:options][:id]).to eq ip_retention_global.ip_retention_container_id
        expect(event[:options][:ip_retention_id]).to eq ip_retention_global.ip_retention_container_id
        expect(event[:options][:ip_lease_id]).to eq ip_retention_global.ip_lease_id
        expect(event[:options][:leased_at]).to eq ip_retention_global.leased_at
        expect(event[:options][:released_at]).to eq current_time
      end

      events[2].tap do |event|
        expect(event[:event]).to eq Vnet::Event::IP_RETENTION_CONTAINER_ADDED_IP_RETENTION
        expect(event[:options][:id]).to eq ip_retention_user.ip_retention_container_id
        expect(event[:options][:ip_retention_id]).to eq ip_retention_user.ip_retention_container_id
        expect(event[:options][:ip_lease_id]).to eq ip_retention_user.ip_lease_id
        expect(event[:options][:leased_at]).to eq ip_retention_user.leased_at
        expect(event[:options][:released_at]).to eq current_time
      end
    end
  end
end
