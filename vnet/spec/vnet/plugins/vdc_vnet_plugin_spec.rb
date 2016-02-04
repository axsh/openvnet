# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Plugins::VdcVnetPlugin do

  before do
    use_mock_event_handler
  end

  subject { Vnet::Plugins::VdcVnetPlugin.new }

  def deep_copy(h)
    Marshal.load( Marshal.dump(h) )
  end

  context "when an entry of Network is created on vdc" do
    let(:model_class) { :Network }
    let(:params) do
      {
        :uuid => "nw-testuuid",
        :display_name => "test_name",
        :ipv4_network => "1.2.3.0",
        :ipv4_prefix => 24,
        :domain_name => "test_domain",
        :network_mode => 'virtual',
      }
    end
    let!(:datapath) { Fabricate(:datapath_1) }
    let!(:host_port) do
      network = Fabricate(:pnet_public1, uuid: 'nw-public')

      interface = Fabricate(:host_port_any)
      interface_port = Fabricate(:interface_port_eth0,
                                 interface_id: interface.id,
                                 datapath_id: datapath.id)

      mac_lease = Fabricate(:mac_lease_any, interface: interface)
      ip_address = Fabricate(:ip_address, network: network)
      ip_lease = Fabricate(:ip_lease_any,
                           mac_lease: mac_lease,
                           network_id: network.id,
                           ip_address: ip_address)

      interface.add_ip_lease(ip_lease)
      interface
    end

    describe "create_entry" do
      it "creates a record of Network on vnet" do
        subject.create_entry(model_class, deep_copy(params))
        entry = Vnet::Models::Network[params[:uuid]]

        expect(entry).not_to eq nil
        expect(entry.canonical_uuid).to eq params[:uuid]

        dpn = Vnet::Models::DatapathNetwork.find({
          :datapath_id => datapath.id,
          :network_id => entry.id
        })

        expect(dpn).not_to eq nil
      end
    end

    describe "destroy_entry" do
      it "deletes a record of Network on vnet" do
        subject.create_entry(model_class, deep_copy(params))
        subject.destroy_entry(model_class, deep_copy(params))

        expect(Vnet::Models::Network[params[:uuid]]).to eq nil
      end
    end
  end

  context "when network_vif is created" do
    let(:model_class) { :NetworkVif }
    let(:params) do
      {
        :uuid => "if-testuuid",
        :port_name => "if-testuuid",
        :mac_address => "52:54:00:12:5c:69",
      }
    end

    describe "create_entry" do
      it "creates an entry of Interface" do
        subject.create_entry(model_class, deep_copy(params))
        interface_uuid = params[:uuid].gsub("vif-", "if-")
        entry = Vnet::Models::Interface[interface_uuid]

        expect(entry).not_to eq nil
        expect(entry.canonical_uuid).to eq interface_uuid
      end
    end

    describe "destroy_entry" do
      it "deletes an entry of Interface" do
        subject.create_entry(model_class, deep_copy(params))
        subject.destroy_entry(model_class, deep_copy(params))
        expect(Vnet::Models::Interface[params[:uuid]]).to eq nil
      end
    end
  end

  context "when network_route is created" do

    let(:datapath) do
      MockDatapath.new(double, ("0x#{'a' * 16}").to_i(16)).tap do |dp|
        dp.create_mock_datapath_map
        dp.dp_info.added_flows.clear
      end
    end

    let(:dp_info) { datapath.dp_info }

    let(:model_class) { :NetworkRoute }

    let(:outer_network) { Fabricate(:pnet_public2) }
    let(:inner_network) { Fabricate(:vnet_1) }

    let!(:datapath1) { Fabricate(:datapath_1) }
    let!(:host_port) {
      interface = Fabricate(:host_port_any)
      interface_port = Fabricate(:interface_port_host,
                                 interface_id: interface.id,
                                 datapath_id: datapath1.id,
                                 port_name: "test")
      interface
    }
    let!(:gw_interface) do
      interface = Fabricate(:interface)
      interface.mode = 'simulated'
      interface.enable_routing = true
      interface.enable_route_translation = true
      interface.display_name = "gw_#{outer_network.canonical_uuid}"

      interface_port = Fabricate(:interface_port_wanedge,
                                 interface_id: interface.id,
                                 datapath_id: datapath.datapath_info.id)

      mac_lease = Fabricate(:mac_lease_any) do
        mac_address 1
        interface_id interface.id
      end

      ip_lease = Fabricate(:ip_lease_any,
                           interface: interface,
                           mac_lease: mac_lease,
                           network_id: outer_network.id,
                           ipv4_address: IPAddress("192.168.2.2").to_i)

      interface.add_ip_lease(ip_lease)
      interface.save
      interface
    end

    let(:params) do
      {
        :ingress_ipv4_address => "192.168.2.33",
        :egress_ipv4_address => "10.102.0.10",
        :outer_network_uuid => outer_network.canonical_uuid,
        :inner_network_uuid => inner_network.canonical_uuid,
        :outer_network_gw => "192.168.2.1",
        :inner_network_gw => "10.102.0.1"
      }
    end

    before do
      Vnet::NodeApi::ActiveInterface.create({
       :interface_id => host_port.id,
        :datapath_id => datapath1.id,
        :label => datapath1.canonical_uuid,
        :singular => nil,
        :enable_routing => true
      })
    end

    describe "create_entry" do
      it "creates translation entry" do
        subject.create_entry(model_class, deep_copy(params))

        outer_gw = Vnet::Models::Interface.find({:display_name => "gw_#{outer_network.canonical_uuid}"})
        inner_gw = Vnet::Models::Interface.find({:display_name => "gw_#{inner_network.canonical_uuid}"})

        outer_gw_port = outer_gw.interface_ports.first
        inner_gw_port = inner_gw.interface_ports.first

        expect(outer_gw).not_to eq nil
        expect(outer_gw_port.datapath_id).to eq datapath1.id
        expect(outer_gw.enable_routing).to eq true
        expect(outer_gw.enable_route_translation).to eq true

        expect(inner_gw).not_to eq nil
        expect(inner_gw_port.datapath_id).to eq nil
        expect(inner_gw.enable_routing).to eq true
        expect(inner_gw.enable_route_translation).to eq false

        route_inner = Vnet::Models::Route.find({:network_id => inner_network.id})
        route_outer = Vnet::Models::Route.find({:network_id => outer_network.id})

        expect(route_inner).not_to eq nil
        expect(route_outer).not_to eq nil
        expect(route_inner.route_link.id).to eq route_outer.route_link.id

        datapath_route_link = Vnet::Models::DatapathRouteLink.all.first

        expect(datapath_route_link).not_to eq nil
        expect(datapath_route_link.datapath_id).to eq datapath1.id
        expect(datapath_route_link.interface_id).to eq host_port.id
        expect(datapath_route_link.route_link_id).to eq route_inner.route_link.id

        translation = Vnet::Models::Translation.find({:mode => 'static_address'})

        expect(translation).not_to eq nil
        expect(translation.mode).to eq 'static_address'

        tsa = Vnet::Models::TranslationStaticAddress.find({
          :ingress_ipv4_address => IPAddr.new(params[:ingress_ipv4_address]).to_i,
          :egress_ipv4_address => IPAddr.new(params[:egress_ipv4_address]).to_i
        })

        expect(tsa).not_to eq nil
        expect(tsa.ingress_ipv4_address).to eq IPAddr.new(params[:ingress_ipv4_address]).to_i
      end
    end
  end
end
