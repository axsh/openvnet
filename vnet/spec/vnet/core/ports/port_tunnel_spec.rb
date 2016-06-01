# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

include Vnet::Constants::Openflow

describe Vnet::Core::Ports::Tunnel do
  describe "install" do

    let(:datapath) { MockDatapath.new(double, 10) }
    let(:dp_info) { datapath.dp_info }

    it "creates tunnel specific flows" do
      port = Vnet::Core::Ports::Base.new(dp_info: dp_info,
                                         id: 10,
                                         port_desc: double(port_no: 10, name: 't-a'))
      port.extend(Vnet::Core::Ports::Tunnel)
      port.dst_datapath_id = 5

      tunnel_manager = double(:tunnel_manager)

      # update_item is now called from port manager.
      allow(tunnel_manager).to receive(:update)
      allow(datapath.dp_info).to receive(:tunnel_manager).and_return(tunnel_manager)

      port.try_install

      expect(dp_info.added_ovs_flows.size).to eq 0
      expect(dp_info.added_flows.size).to eq(1 + DATAPATH_IDLE_FLOWCOUNT)

      expect(dp_info.added_flows).to include Vnet::Openflow::Flow.create(
                                              TABLE_TUNNEL_PORTS,
                                              30,
                                              {:in_port => 10},
                                              nil,
                                              {:cookie => 10 | (COOKIE_PREFIX_PORT << COOKIE_PREFIX_SHIFT),
                                               :goto_table => TABLE_TUNNEL_IDS})
    end

  end

end
