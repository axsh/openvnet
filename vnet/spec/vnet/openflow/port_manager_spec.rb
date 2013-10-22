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

        tunnel = double(:tunnel)
        tunnel.should_receive(:dst_id).and_return(1)

        Vnet::Openflow::TunnelManager.any_instance.stub(:item).and_return(tunnel)

        dp.create_mock_port_manager
        port_desc = double(:port_desc)
        port_desc.should_receive(:port_no).exactly(3).times.and_return(5)
        port_desc.should_receive(:name)
        port_desc.should_receive(:hw_addr)
        port_desc.should_receive(:advertised).and_return(100)
        port_desc.should_receive(:supported).and_return(100)

        port = double(:port)
        port_info = double(:port_info)
        port.should_receive(:port_name).exactly(1).times.and_return("t-src1dst3")
        port.should_receive(:port_number).exactly(2).times.and_return(5)
        port.should_receive(:port_info).exactly(3).times.and_return(port_info)
        port.should_receive(:extend).and_return(Vnet::Openflow::Ports::Tunnel)
        port.should_receive(:dst_id=)
        port.should_receive(:to_hash)
        port.should_receive(:install)
        port_info.should_receive(:name).exactly(3).times.and_return("t-src1dst3")

        Vnet::Openflow::Ports::Base.stub(:new).and_return(port)

        dp.port_manager.insert(port_desc)

        expect(dp.port_manager.ports[5]).to eq port
      end
    end

    context "eth" do
      before do
        Fabricate(:interface, uuid: "if-eth0")
      end

      it "creates an object of Models::Interface for eth0" do
        nm = double(:network_manager)
        nm.should_receive(:set_datapath_info)
        Vnet::Openflow::NetworkManager.stub(:new).and_return(nm)

        ofc = double(:ofc)
        dp = MockDatapath.new(ofc, 1)
        dp.create_mock_port_manager

        port_desc = double(:port_desc)
        port_desc.should_receive(:port_no).exactly(3).times.and_return(1)
        port_desc.should_receive(:name).twice
        port_desc.should_receive(:hw_addr)
        port_desc.should_receive(:advertised).and_return(1)
        port_desc.should_receive(:supported).and_return(1)

        port = double(:port)
        port_info = double(:port_info)
        port_info.should_receive(:name).and_return('eth0')
        port.should_receive(:port_number).exactly(2).times.and_return(1)
        port.should_receive(:port_info).and_return(port_info)
        port.should_receive(:to_hash)
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
        iface = Fabricate(:interface)

        ip_addr = Fabricate(:ip_address_1, network: vnet)
        mac = Fabricate(:mac_address)
        mac_lease = Fabricate(:mac_lease, interface: iface, _mac_address: mac)
        Fabricate(:ip_lease_any, mac_lease: mac_lease, ip_address: ip_addr, interface: iface)
      end

      it "creates an instance of interface when the switch receives port_status" do
        nm = double(:network_manager)
        nm.should_receive(:set_datapath_info)
        Vnet::Openflow::NetworkManager.stub(:new).and_return(nm)

        ofc = double(:ofc)
        dp = MockDatapath.new(ofc, 1)
        dp.create_mock_port_manager

        port_desc = double(:port_desc)
        port_desc.should_receive(:port_no).exactly(3).times.and_return(2)
        port_desc.should_receive(:name).exactly(3).times.and_return('if-testuuid')
        port_desc.should_receive(:hw_addr)
        port_desc.should_receive(:advertised).and_return(1)
        port_desc.should_receive(:supported).and_return(1)

        port = double(:port)
        port_info = double(:port_info)
        port_info.should_receive(:name).twice.and_return('if-testuuid')
        port.should_receive(:port_number).exactly(3).times.and_return(2)
        port.should_receive(:port_info).twice.and_return(port_info)
        port.should_receive(:to_hash)

        Vnet::Openflow::Ports::Base.stub(:new).and_return(port)
        dp.port_manager.insert(port_desc)
      end
    end
  end
end
