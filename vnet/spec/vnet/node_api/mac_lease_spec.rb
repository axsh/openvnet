# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }

describe Vnet::NodeApi::MacLease do
  before(:each) { use_mock_event_handler }

  let(:events) { MockEventHandler.handled_events }

  let(:interface) { Fabricate(:interface) }
  let(:segment) { Fabricate(:segment) }

  let(:random_mac_address) { random_mac_i }

  let(:model_params) {
    { interface_id: interface_id,
      segment_id: segment_id,
      mac_address: random_mac_address
    }
  }

  # TODO: Add permutations for enable_routing.

  describe 'create' do
    let(:interface_event) {
      [ Vnet::Event::INTERFACE_LEASED_MAC_ADDRESS, {
          id: interface.id,
          mac_lease_id: :model__id,
          # segment_id: :let__segment_id,
          # mac_address: random_mac_address
        }]
    }
    let(:create_events) {
      [].tap { |event_list|
        event_list << interface_event if with_lets.include?('interface_id')
      }
    }
    let(:create_result) { model_params }
    let(:query_result) { create_result }
    let(:extra_creations) { [:mac_address] }

    include_examples 'create item on node_api with lets', :mac_lease, let_ids: [:interface, :segment]
  end

  describe 'update' do
    let(:model) { Fabricate(:mac_lease_any, model_params) }
    let(:update_filter) { model.canonical_uuid }

    let(:interface_leased_event) {
      [ Vnet::Event::INTERFACE_LEASED_MAC_ADDRESS, {
          id: interface.id,
          mac_lease_id: model.id
        }]
    }
    let(:interface_released_event) {
      [ Vnet::Event::INTERFACE_RELEASED_MAC_ADDRESS, {
          id: interface.id,
          mac_lease_id: model.id
        }]
    }
    let(:update_events) {
      [].tap { |event_list|
        event_list << interface_released_event if interface_id
        event_list << interface_leased_event if interface_id.nil?
      }
    }
    let(:update_params) {
      {}.tap { |params|
        params[:interface_id] = (interface_id ? nil : interface.id)
      }
    }

    # TODO: Currently we update all valid update fields at the same
    # time.
    # TODO: We currently only support specs for changing an id either
    # from or to nil.

    include_examples 'update item on node_api with lets', :mac_lease, let_ids: [:interface, :segment]
  end

  describe 'destroy' do
    let(:model) { Fabricate(:mac_lease_any, model_params) }
    let(:delete_filter) { model.canonical_uuid }

    let(:interface_event) {
      [ Vnet::Event::INTERFACE_RELEASED_MAC_ADDRESS, {
          id: interface.id,
          mac_lease_id: model.id
        }]
    }
    let(:delete_events) {
      [].tap { |event_list|
        event_list << interface_event if with_lets.include?('interface_id')
      }
    }
    let(:extra_deletions) { [:mac_address] }

    include_examples 'delete item on node_api with lets', :mac_lease, let_ids: [:interface, :segment]
  end
end
