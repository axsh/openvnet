# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::NodeApi::Interface do
  before do
    use_mock_event_handler
  end

  describe "create" do
    it "with associations" do
      network = Fabricate(:network)
      datapath = Fabricate(:datapath)

      interface = Vnet::NodeApi::Interface.execute(:create,
        uuid: "if-test",
        network_id: network.id,
        ipv4_address: 1,
        mac_address: 2,
        owner_datapath_id: datapath.id
      )

      expect(interface[:uuid]).to eq "if-test"
      model = Vnet::Models::Interface["if-test"]
      expect(model.network.id).to eq network.id
      expect(model.ipv4_address).to eq 1
      expect(model.mac_address).to eq 2
      # expect(model.owner_datapath.id).to eq datapath.id

      events = MockEventHandler.handled_events
      expect(events.size).to eq 2
      expect(events.first[:event]).to eq Vnet::Event::INTERFACE_CREATED_ITEM
      expect(events.first[:options][:id]).to eq interface[:id]
      expect(events.first[:options][:port_name]).to eq interface[:port_name]
    end
  end

  describe "update" do
    let(:datapath) { Fabricate(:datapath) }
    let(:dp_info) { datapath.dp_info }
    let(:interface) do
      Fabricate(:interface,
        mac_leases: [
          Fabricate(:mac_lease,
            mac_address: 2,
            ip_leases: [
              Fabricate(:ip_lease,
                ipv4_address: 1,
                network_id: Fabricate(:network).id)
            ])])
    end

    it "success" do
      Vnet::NodeApi::Interface.execute(:update,
        interface.canonical_uuid,
        {
          # owner_datapath: Fabricate(:datapath, uuid: "dp-new"),
        }  
      )

      model = Vnet::Models::Interface[interface.id]
      # expect(model.owner_datapath.canonical_uuid).to eq "dp-new"

      events = MockEventHandler.handled_events
      expect(events.size).to eq 1
      expect(events.first[:event]).to eq Vnet::Event::INTERFACE_UPDATED
      expect(events.first[:options][:id]).to eq interface[:id]
    end
  end

  describe "delete" do
    let(:network) { Fabricate(:network) }
    let(:datapath) { Fabricate(:datapath) }
    let(:dp_info) { datapath.dp_info }
    let(:interface) do
      Fabricate(:interface,
        mac_leases: [
          Fabricate(:mac_lease,
            mac_address: 2,
            ip_leases: [
              Fabricate(:ip_lease,
                ipv4_address: 1,
                network_id: network.id)
            ])])
    end

    it "with associations" do
      Vnet::NodeApi::Interface.execute(:destroy, interface.canonical_uuid)

      expect(Vnet::Models::Interface[interface.id]).to be_nil

      events = MockEventHandler.handled_events
      expect(events.size).to eq 2
      expect(events.first[:event]).to eq Vnet::Event::INTERFACE_DELETED_ITEM
      expect(events.first[:options][:id]).to eq interface[:id]
      expect(events.last[:event]).to eq Vnet::Event::INTERFACE_RELEASED_MAC_ADDRESS
      expect(events.last[:options][:id]).to eq interface[:id]
    end
  end
end
