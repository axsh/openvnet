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

  describe 'create' do
    let(:interface_event) {
      [ Vnet::Event::INTERFACE_LEASED_MAC_ADDRESS, {
          id: :let__interface_id,
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

  describe 'destroy' do
    let(:model) { Fabricate(:mac_lease_any, model_params) }
    let(:delete_filter) { model.canonical_uuid }

    # TODO: Fix released event when without interface_id.
    let(:interface_event) {
      [ Vnet::Event::INTERFACE_RELEASED_MAC_ADDRESS, {
          id: :let__interface_id,
          mac_lease_id: :model__id
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
