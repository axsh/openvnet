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
  let(:ip_retention) { Fabricate(:ip_retention_with_container, ip_lease: model) }

  let(:random_ipv4_address) { random_ipv4_i }

  let(:model_params) {
    { mac_lease: mac_lease,
      network_id: network.id,
      interface_id: interface_id,
      ipv4_address: random_ipv4_address
    }
  }

  describe 'create' do
    let(:create_result) {
      { network_id: network.id,
        mac_lease_id: mac_lease.id,
        enable_routing: false,
        ipv4_address: random_ipv4_address,
      }
    }
    let(:interface_event) { [
        Vnet::Event::INTERFACE_LEASED_IPV4_ADDRESS, {
          id: :let__interface_id,
          ip_lease_id: :model__id,
          # uuid: :model__uuid,
          # ipv4_address: random_ipv4_address,
          # network_id: network.id,
          # mac_lease_id: mac_lease.id,
          # enable_routing: false,
        }]
    }
    let(:create_events) {
      [].tap { |event_list|
        event_list << interface_event if with_lets.include?('interface_id')
      }
    }
    let(:query_result) { create_result }
    let(:extra_creations) { [:ip_address] }

    include_examples 'create item on node_api with lets', :ip_lease, let_ids: [:interface, :segment]
  end

  describe 'destroy' do
    let(:model) { Fabricate(:ip_lease, model_params) }
    let(:delete_filter) { model.canonical_uuid }
    let(:interface_event) { [
        Vnet::Event::INTERFACE_RELEASED_IPV4_ADDRESS, {
          id: :let__interface_id,
          ip_lease_id: :model__id
        }]
    }
    let(:ip_retention_event) { [
        Vnet::Event::IP_RETENTION_CONTAINER_REMOVED_IP_RETENTION, {
          id: ip_retention.id
        }]
    }
    let(:delete_events) {
      [].tap { |event_list|
        event_list << interface_event if with_lets.include?('interface_id')
        event_list << ip_retention_event if with_lets.include?('ip_retention_id')
      }
    }
    let(:extra_deletions) {
      [:ip_address].tap { |deletions|
        deletions << :ip_retention if with_lets.include?('ip_retention_id')
      }
    }

    include_examples 'delete item on node_api with lets', :ip_lease, let_ids: [:interface, :segment, :ip_retention]
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
