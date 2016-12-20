# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }

describe Vnet::NodeApi::InterfaceNetwork do
  before(:each) { use_mock_event_handler }

  let(:interface) { Fabricate(:interface) }
  let(:other) { Fabricate(:network) }

  let(:if_assoc_static) {
    { interface_id: interface.id,
      network_id: other.id,
      static: true,
      is_deleted: 0
    }
  }
  let(:if_assoc_non_static) { if_assoc_static.merge(static: false) }

  let(:create_lease) { Fabricate(:ip_lease_free, interface_id: interface.id, network_id: other.id) }
  let(:create_if_assoc_static) { Fabricate(:interface_network, if_assoc_static) }
  let(:create_if_assoc_no_static) { Fabricate(:interface_network, if_assoc_non_static) }

  let(:node_api) { Vnet::NodeApi::InterfaceNetwork }
  let(:created_event_type) { Vnet::Event::INTERFACE_NETWORK_CREATED_ITEM }
  let(:deleted_event_type) { Vnet::Event::INTERFACE_NETWORK_DELETED_ITEM }
  let(:updated_event_type) { Vnet::Event::INTERFACE_NETWORK_UPDATED_ITEM }

  include_examples 'interface assoc on node_api'
end
