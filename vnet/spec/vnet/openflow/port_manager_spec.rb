# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

describe Vnet::Openflow::PortManager do
  describe "insert" do
    context "tunnel" do
      it "should create a port object whose datapath_id is 1" do
        ofc = double(:ofc)
        dp = MockDatapath.new(ofc, 1)
        Vnet::Openflow::TunnelManager.any_instance.stub(:create_all_tunnels)
        dp.create_mock_port_manager
        port_desc = double(:port_desc)
        port_desc.should_receive(:port_no).and_return(5)

        port = double(:port)
        port_info = double(:port_info)
        port.should_receive(:port_number).exactly(2).times.and_return(5)
        port.should_receive(:port_info).exactly(3).times.and_return(port_info)
        port.should_receive(:extend).and_return(Vnet::Openflow::Ports::Tunnel)
        port.should_receive(:install)
        port_info.should_receive(:name).exactly(3).times.and_return("t-src1dst3")

        Vnet::Openflow::Ports::Base.stub(:new).and_return(port)

        dp.port_manager.insert(port_desc)

        expect(dp.port_manager.ports[5]).to eq port
      end
    end

    context "eth" do
      before do
        Fabricate(:eth0)
      end

      it "creates an object of Models::Interface for eth0" do
        nm = double(:network_manager)
        nm.should_receive(:network_by_uuid).and_return(nil)
        Vnet::Openflow::NetworkManager.stub(:new).and_return(nm)

        ofc = double(:ofc)
        dp = MockDatapath.new(ofc, 1)
        dp.create_mock_port_manager

        port_desc = double(:port_desc)
        port_desc.should_receive(:port_no).and_return(1)

        port = double(:port)
        port_info = double(:port_info)
        port_info.should_receive(:name).twice.and_return('eth0')
        port.should_receive(:port_number).twice.and_return(1)
        port.should_receive(:port_info).twice.and_return(port_info)
        port.should_receive(:install)

        Vnet::Openflow::Ports::Base.stub(:new).and_return(port)

        dp.port_manager.insert(port_desc)

        expect(dp.port_manager.ports[1]).to eq port
      end
    end

    context "vif" do
      before do
        Fabricate(:datapath_1)

        vnet = Fabricate(:vnet_1)
        iface = Fabricate(:iface_2, network: vnet)

        ip_addr = Fabricate(:ip_address_1)
        mac = Fabricate(:mac_address)
        Fabricate(:mac_lease, interface: iface, mac_address: mac)
        Fabricate(:ip_lease_1, ip_address: ip_addr, interface: iface)
      end

      it "creates an instance of interface when the switch receives port_status" do
        network = double(:network)
        network.should_receive(:add_port)
        network.should_receive(:class).twice.and_return(Vnet::Openflow::NetworkVirtual)

        nm = double(:network_manager)
        nm.should_receive(:network_by_uuid).and_return(network)
        Vnet::Openflow::NetworkManager.stub(:new).and_return(nm)

        ofc = double(:ofc)
        dp = MockDatapath.new(ofc, 1)
        dp.create_mock_port_manager

        port_desc = double(:port_desc)
        port_desc.should_receive(:port_no).exactly(9).times.and_return(2)
        port_desc.should_receive(:name).exactly(3).times.and_return('if-testuuid')

        dp.port_manager.insert(port_desc)
      end
    end
  end
end
