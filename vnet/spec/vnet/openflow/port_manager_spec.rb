# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

include Vnet::Constants::Openflow

describe Vnet::Openflow::PortManager do

  describe "prepare_port_eth" do
    let!(:datapath_map) { Fabricate(:datapath_1) }

    let!(:interface) do
      Fabricate(:interface) do
        uuid 'if-testeth'
        display_name 'eth1'
        mode 'edge'
        mac_address 1
      end
    end

    let(:datapath) do
      MockDatapath.new(double, ("a" * 16).to_i(16)).tap do |d|
        if_double = double(:interface_double)

        interface_manager = double(:interface_manager)

        vif = double(:vif)
        vif.should_receive(:nil?).and_return(false)
        interface_manager.should_receive(:item).and_return(vif)

        d.should_receive(:mod_port)
        d.should_receive(:interface_manager).and_return(interface_manager)
        d.should_receive(:datapath_map).twice.and_return(datapath_map)
      end
    end

    subject { Vnet::Openflow::PortManager.new(datapath) }

    it "will create an interface object for vnet edge" do

      port_desc = double(:port_desc)
      port_desc.should_receive(:port_no).exactly(10).times.and_return(1)
      port_desc.should_receive(:name).exactly(4).times.and_return(interface.display_name)
      port_desc.should_receive(:hw_addr).and_return(interface.mac_address)
      port_desc.should_receive(:advertised).and_return(1)
      port_desc.should_receive(:supported).and_return(1)

      subject.insert(port_desc)

      expect(datapath.added_flows[0]).to eq Vnet::Openflow::Flow.create(
        TABLE_CLASSIFIER,
        2,
        {:in_port => port_desc.port_no},
        nil,
        {:cookie => port_desc.port_no | (COOKIE_PREFIX_PORT << COOKIE_PREFIX_SHIFT),
         :goto_table => TABLE_EDGE_SRC})
    end
  end
end
