# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }

describe Vnet::NodeApi::InterfaceRouteLink do
  before(:each) { use_mock_event_handler }

  let(:interface) { Fabricate(:interface) }
  let(:other) { Fabricate(:route_link) }

  let(:if_assoc_static) {
    { interface_id: interface.id,
      route_link_id: other.id,
      static: true,
      is_deleted: 0
    }
  }
  let(:if_assoc_non_static) { if_assoc_static.merge(static: false) }

  let(:create_lease) { Fabricate(:route_free, interface_id: interface.id, route_link_id: other.id) }

  let(:create_if_assoc_static) { Fabricate(:interface_route_link, if_assoc_static) }
  let(:create_if_assoc_no_static) { Fabricate(:interface_route_link, if_assoc_non_static) }

  let(:node_api) { Vnet::NodeApi::InterfaceRouteLink }
  let(:created_event_type) { Vnet::Event::INTERFACE_ROUTE_LINK_CREATED_ITEM }
  let(:deleted_event_type) { Vnet::Event::INTERFACE_ROUTE_LINK_DELETED_ITEM }
  let(:updated_event_type) { Vnet::Event::INTERFACE_ROUTE_LINK_UPDATED_ITEM }

  include_examples 'interface assoc on node_api'
end
