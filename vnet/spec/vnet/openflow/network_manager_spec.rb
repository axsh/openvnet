# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

describe Vnet::Openflow::NetworkManager do

  before(:all) do
    use_mock_event_handler
    Fabricate("vnet_1")
    Fabricate("datapath_1")
  end

  let(:datapath) { MockDatapath.new(double, ("a" * 16).to_i(16), double) }

  subject { Vnet::Openflow::NetworkManager.new(datapath) }

  describe "network_by_uuid" do
    it "should dispatch 'network/added' event" do
      subject.network_by_uuid("nw-aaaaaaaa")
      events = MockEventHandler.handled_events
      expect(events[0][:event]).to eq "network/added"
    end
  end
end
