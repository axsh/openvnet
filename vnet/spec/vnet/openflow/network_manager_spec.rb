# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

describe Vnet::Openflow::NetworkManager do

  before do
    Fabricate(:vnet_1)
    Fabricate(:vnet_2)
    Fabricate(:datapath_1)
    Fabricate(:datapath_network_1_1)
    Fabricate(:datapath_network_1_2)
  end

  let(:network_manager) { Vnet::Openflow::NetworkManager.new(datapath) }

  describe "network_by_id" do
    let(:datapath) do
      MockDatapath.new(double, ("a" * 16).to_i(16)).tap do |dp|
        dp.create_datapath_map

        actor = double(:actor)
        actor.should_receive(:prepare_network).exactly(2).and_return(true)

        dc_segment_manager = double(:dc_segment_manager)
        tunnel_manager = double(:tunnel_manager)

        dc_segment_manager.should_receive(:async).and_return(actor)
        tunnel_manager.should_receive(:async).and_return(actor)


        dp.should_receive(:dc_segment_manager).and_return(dc_segment_manager)
        dp.should_receive(:tunnel_manager).and_return(tunnel_manager)
      end
    end

    subject { use_mock_event_handler; network_manager.item(uuid: 'nw-aaaaaaaa') }

    it { should be_a Hash }
    it { expect(subject[:uuid]).to eq 'nw-aaaaaaaa' }
    it { expect(subject[:type]).to eq :virtual }
  end

  describe "remove" do
    let(:datapath) do
      MockDatapath.new(double, ("a" * 16).to_i(16)).tap do |dp|
        dp.create_datapath_map

        actor = double(:actor)
        actor.should_receive(:prepare_network).exactly(2).and_return(true)
        actor.should_receive(:remove_network_id).and_return(true)

        dc_segment_manager = double(:dc_segment_manager)
        tunnel_manager = double(:tunnel_manager)

        dc_segment_manager.should_receive(:async).twice.and_return(actor)
        tunnel_manager.should_receive(:async).and_return(actor)


        dp.should_receive(:dc_segment_manager).twice.and_return(dc_segment_manager)
        dp.should_receive(:tunnel_manager).and_return(tunnel_manager)
      end
    end

    it "has no flow after delete the last network on itself" do
      network = network_manager.item(uuid: 'nw-aaaaaaaa')
      network_manager.remove(network[:id])
      expect(datapath.added_flows).to eq []
    end
  end

  describe "network_by_uuid_direct" do
    let(:datapath) do
      MockDatapath.new(double, ("a" * 16).to_i(16)).tap do |dp|
        dp.create_datapath_map

        actor = double(:actor)
        actor.should_receive(:prepare_network).exactly(4).and_return(true)

        dc_segment_manager = double(:dc_segment_manager)
        tunnel_manager = double(:tunnel_manager)

        dc_segment_manager.should_receive(:async).twice.and_return(actor)
        tunnel_manager.should_receive(:async).twice.and_return(actor)


        dp.should_receive(:dc_segment_manager).twice.and_return(dc_segment_manager)
        dp.should_receive(:tunnel_manager).twice.and_return(tunnel_manager)
      end
    end
    
    subject do
      network_manager.item(uuid: 'nw-aaaaaaaa')
      network_manager.item(uuid: 'nw-bbbbbbbb')
      network_manager.item(uuid: 'nw-aaaaaaaa', dynamic_load: false)
    end

    it { expect(subject[:uuid]).to eq 'nw-aaaaaaaa' }
  end
end
