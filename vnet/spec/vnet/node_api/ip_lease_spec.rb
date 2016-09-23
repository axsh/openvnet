# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }

describe Vnet::NodeApi::IpLease do
  before(:each) { use_mock_event_handler }

  let(:events) { MockEventHandler.handled_events }

  let(:interface) { Fabricate(:interface) }
  let(:network) { Fabricate(:network) }
  let(:segment) { Fabricate(:segment) }

  let(:mac_lease) { Fabricate(:mac_lease, interface_id: interface_id, segment_id: segment_id) }

  describe 'create' do
    let(:random_ipv4_address) { random_ipv4_i }
    
    let(:create_filter) {
      { mac_lease: mac_lease,
        network_id: network.id,
        ipv4_address: random_ipv4_address
      }
    }
    # TODO: Add helper that lets us check if e.g. 'id', 'uuid',
    # foo_at, etc are valid.
    let(:create_result) {
      { #id: 1,
        #uuid: "il-bmj379ro"
        #interface_id: interface.id,
        network_id: network.id,
        mac_lease_id: mac_lease.id,
        enable_routing: false,
        #ip_address_id: 1,
        ipv4_address: random_ipv4_address,
        #class_name: "IpLease",
        #created_at: 2016-09-22 15:44:12.000000000 +0000,
        #updated_at: 2016-09-22 15:44:12.000000000 +0000,
        #deleted_at: nil,
        #is_deleted: 0,
      }
    }
    let(:create_events) {
      [ [ Vnet::Event::INTERFACE_LEASED_IPV4_ADDRESS, {
            id: :let__interface_id,
            uuid: :model__uuid,
            ip_lease_id: :model__id,
            ipv4_address: random_ipv4_address,
            network_id: network.id,
            mac_lease_id: mac_lease.id,
            enable_routing: false,
          }]]
    }
    let(:query_result) { create_result }

    context 'without interface and without segment' do
      let(:interface_id) { nil }
      let(:segment_id) { nil }
      let(:create_events) { [] }

      include_examples 'create item on node_api', :ip_lease, [:ip_address]
    end

    context 'with interface and without segment' do
      let(:interface_id) { interface.id }
      let(:segment_id) { nil }
      include_examples 'create item on node_api', :ip_lease, [:ip_address]
    end

    context 'without interface and with segment' do
      let(:interface_id) { nil }
      let(:segment_id) { segment.id }
      let(:create_events) { [] }

      include_examples 'create item on node_api', :ip_lease, [:ip_address]
    end

    context 'with interface and with segment' do
      let(:interface_id) { interface.id }
      let(:segment_id) { segment.id }
      include_examples 'create item on node_api', :ip_lease, [:ip_address]
    end
  end

  describe 'destroy' do
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

  describe 'release' do
    it 'success' do
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
