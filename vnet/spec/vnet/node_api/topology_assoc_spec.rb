# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }

describe Vnet::NodeApi::TopologyNetwork do
  before(:each) { use_mock_event_handler }

  let(:events) { MockEventHandler.handled_events }

  let(:network) { Fabricate(:network) }
  let(:topology) { Fabricate(:topology, mode: 'simple') }

  let(:model_params) {
    { network_id: network.id,
      topology_id: topology.id
    }
  }

  let(:topology_added_network_event) {
    [ Vnet::Event::TOPOLOGY_ADDED_NETWORK, {
        id: topology.id,
        network_id: network.id
      }]
  }
  let(:topology_removed_network_event) {
    [ Vnet::Event::TOPOLOGY_REMOVED_NETWORK, {
        id: topology.id,
        network_id: network.id
      }]
  }

  describe 'create' do
    let(:create_result) { model_params }
    let(:query_result) { create_result }
    let(:create_events) { [topology_added_network_event] }
    let(:extra_creations) { [] }

    include_examples 'create item on node_api with lets', :topology_network, let_ids: []
  end

  describe 'update' do
    let(:model) { Fabricate(:topology_network, model_params) }
    let(:update_filter) { { id: model.id } }
    let(:update_events) { [] }
    let(:update_params) { {} }

    include_examples 'update item on node_api with lets', :topology, let_ids: []
  end

  describe 'destroy' do
    let(:model) { Fabricate(:topology_network, model_params) }
    let(:delete_filter) { { id: model.id } }
    let(:delete_events) { [topology_removed_network_event] }
    let(:extra_deletions) { [] }

    include_examples 'delete item on node_api with lets', :topology_network, let_ids: []
  end

end
