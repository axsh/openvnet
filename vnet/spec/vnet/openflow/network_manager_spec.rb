# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

describe Vnet::Openflow::NetworkManager do

  before(:all) do
    use_mock_event_handler
    Fabricate("vnet_1")
    Fabricate("datapath_1")
    Fabricate("datapath_network_1_1")
  end

  let(:datapath) do
    MockDatapath.new(double, ("a" * 16).to_i(16), double).tap do |dp|
      manager = double(:manager)
      manager.stub(:prepare_network).and_return(true)

      actor = double(:actor)
      actor.should_receive(:async).exactly(3).and_return(manager)

      dp.should_receive(:dc_segment_manager).and_return(actor)
      dp.should_receive(:tunnel_manager).and_return(actor)
      dp.should_receive(:route_manager).and_return(actor)
    end
  end

  subject { Vnet::Openflow::NetworkManager.new(datapath) }

  describe "network_by_uuid" do
    it "should dispatch 'network/added' event" do
      subject.network_by_uuid("nw-aaaaaaaa")
      events = MockEventHandler.handled_events
      expect(events[0][:event]).to eq "network/added"
    end
  end
end
