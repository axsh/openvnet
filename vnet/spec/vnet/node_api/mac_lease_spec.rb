# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }

describe Vnet::NodeApi::MacLease do
  before(:each) { use_mock_event_handler }

  let(:events) { MockEventHandler.handled_events }

  let(:interface) { Fabricate(:interface) }
  let(:segment) { Fabricate(:segment) }

  let(:random_mac_address) { random_mac_i }

  describe 'create' do
    let(:create_filter) {
      { interface_id: interface_id,
        segment_id: segment_id,
        mac_address: random_mac_address
      }
    }

    # TODO: Fix leased event when without interface_id.
    let(:create_events) {
      [ [ Vnet::Event::INTERFACE_LEASED_MAC_ADDRESS, {
            id: :let__interface_id,
            segment_id: :let__segment_id,
            mac_lease_id: :model__id,
            mac_address: random_mac_address
          }]]
    }
    let(:create_result) { create_filter }
    let(:query_result) { create_result }

    include_examples 'create item on node_api with lets', :mac_lease, extra_creations: [:mac_address], let_ids: [:interface, :segment]
  end

  describe 'destroy' do
    let(:delete_params) {
      { interface_id: interface_id,
        segment_id: segment_id,
        mac_address: random_mac_address
      }
    }

    let(:delete_item) { Fabricate(:mac_lease_any, delete_params) }
    let(:delete_filter) { delete_item.canonical_uuid }

    # TODO: Fix released event when without interface_id.
    let(:delete_events) {
      [ [ Vnet::Event::INTERFACE_RELEASED_MAC_ADDRESS, {
            id: :let__interface_id,
            mac_lease_id: :model__id
          }]]
    }

    include_examples 'delete item on node_api with lets', :mac_lease, extra_creations: [:mac_address], let_ids: [:interface, :segment]
  end
end
