# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

describe Vnet::Core::Datapaths::Host do

  let(:obj_map) {
    { id: 1,
      uuid: 'dp-test',
      display_name: 'test',
      dpid: 1,
      node_id: 'vna_test'
    }
  }

  subject {
    Vnet::Core::Datapaths::Host.new(dp_info: MockDpInfo.new(dpid: 1), map: OpenStruct.new(obj_map))
  }

  include_examples 'datapath item added', :network
  include_examples 'datapath item added', :segment
  include_examples 'datapath item added', :route_link

end
