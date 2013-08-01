# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

describe Vnet::Openflow::NetworkManager do

  before do
    Fabricate("vnet_1")
    Fabricate("datapath_1")
  end

  let(:datapath) do
    MockDatapath.new(double, ("a" * 16).to_i(16), double).tap do |dp|
      switch = double(:switch)

      tunnel_manager = double(:tunnel_manager)
      route_manager = double(:route_manager)
      dc_segment_manager = double(:dc_segment_manager)

      actor = double(:celluloid_actor)

      actor.should_receive(:prepare_network).exactly(3).and_return(true)

      tunnel_manager.should_receive(:async).and_return(actor)
      route_manager.should_receive(:async).and_return(actor)
      dc_segment_manager.should_receive(:async).and_return(actor)

      switch.should_receive(:tunnel_manager).and_return(tunnel_manager)
      switch.should_receive(:route_manager).and_return(route_manager)
      switch.should_receive(:dc_segment_manager).and_return(dc_segment_manager)

      dp.switch = switch
    end
  end

  describe "network_by_uuid" do
    subject { Vnet::Openflow::NetworkManager.new(datapath) }

    it "should dispatch 'network/added' event" do
      use_mock_event_handler
      subject.network_by_uuid("nw-aaaaaaaa")
      events = MockEventHandler.handled_events
      expect(events[0][:event]).to eq "network/added"
    end
  end
end
