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
        :editable => true
      }
    end

    describe "create_entry" do
      it "creates a record of Network on vnet" do
        subject.create_entry(model_class, deep_copy(params))
        entry = Vnet::Models::Network[params[:uuid]]

        expect(entry).not_to eq nil
        expect(entry.canonical_uuid).to eq params[:uuid]
      end
    end

    describe "destroy_entry" do
      it "deletes a record of Network on vnet" do
        subject.create_entry(model_class, deep_copy(params))
        subject.destroy_entry(model_class, deep_copy(params)[:uuid])

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
        subject.destroy_entry(model_class, deep_copy(params)[:uuid])
        expect(Vnet::Models::Interface[params[:uuid]]).to eq nil
      end
    end
  end

  context "when network_route is created" do

    let(:model_class) { :NetworkRoute }

    let(:outer_network) { Fabricate(:pnet_public2) }
    let(:inner_network) { Fabricate(:vnet_1) }

    let!(:interface_public2gw) do
      interface = Fabricate(:interface_public2gw)
      mac_lease = Fabricate(:mac_lease_any, mac_address: 1, interface: interface)
      ip_lease_any = Fabricate(:ip_lease_any, network_id: outer_network.id, mac_lease: mac_lease, ipv4_address: IPAddr.new("192.168.2.1").to_i)
      interface.add_ip_lease(ip_lease_any)
      interface
    end

    let!(:interface_vnet1gw) do
      interface = Fabricate(:interface_vnet1gw)
      mac_lease = Fabricate(:mac_lease_any, mac_address: 2, interface: interface)
      ip_lease_any = Fabricate(:ip_lease_any, network_id: inner_network.id, mac_lease: mac_lease, ipv4_address: IPAddr.new("10.102.0.1").to_i)
      interface.add_ip_lease(ip_lease_any)
      interface
    end

    let!(:datapath1) { Fabricate(:datapath_1) }
    let!(:host_port) { Fabricate(:host_port_any, active_datapath: datapath1) }

    let(:params) do
      {
        :ingress_ipv4_address => "192.168.2.33",
        :egress_ipv4_address => "10.102.0.10",
        :outer_network_uuid => interface_public2gw.network.canonical_uuid,
        :inner_network_uuid => inner_network.canonical_uuid
      }
    end

    describe "create_entry" do
      it "creates translation entry" do
        subject.create_entry(model_class, deep_copy(params))

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
