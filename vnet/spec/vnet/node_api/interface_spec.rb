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
      expect(model.owner_datapath.id).to eq datapath.id

      events = MockEventHandler.handled_events
      expect(events.size).to eq 1
      expect(events.first[:event]).to eq Vnet::Event::ADDED_INTERFACE
      expect(events.first[:options][:id]).to eq interface[:id]
    end
  end

  describe "update" do
    let(:network_old) { Fabricate(:network) }
    let(:network_new) { Fabricate(:network) }
    let(:datapath) { Fabricate(:datapath) }
    let(:interface) do
      Fabricate(:interface,
        mac_leases: [
          Fabricate(:mac_lease,
            mac_address: 2,
            ip_leases: [
              Fabricate(:ip_lease,
                ipv4_address: 1,
                network_id: network_old.id)
            ])],
        owner_datapath: datapath)
    end

    it "with associations" do
      Vnet::NodeApi::Interface.execute(:update,
        interface.canonical_uuid,
        {
          network_id: network_new.id,
          ipv4_address: 2,
          mac_address: 3,
        }  
      )

      model = Vnet::Models::Interface[interface.id]
      expect(model.network.id).to eq network_new.id
      expect(model.ipv4_address).to eq 2
      expect(model.mac_address).to eq 3

      # TODO test event
      #events = MockEventHandler.handled_events
      #expect(events.size).to eq 1
      #expect(events[0][:event]).to eq "network/interface_added"
      #expect(events[0][:options][:network_id]).to eq network.id
      #expect(events[0][:options][:interface_id]).to eq interface[:id]
    end
  end

  describe "delete" do
    let(:network) { Fabricate(:network) }
    let(:datapath) { Fabricate(:datapath) }
    let(:interface) do
      Fabricate(:interface,
        mac_leases: [
          Fabricate(:mac_lease,
            mac_address: 2,
            ip_leases: [
              Fabricate(:ip_lease,
                ipv4_address: 1,
                network_id: network.id)
            ])],
        owner_datapath: datapath)
    end

    it "with associations" do
      Vnet::NodeApi::Interface.execute(:destroy, interface.canonical_uuid)

      expect(Vnet::Models::Interface[interface.id]).to be_nil

      events = MockEventHandler.handled_events
      expect(events.size).to eq 1
      expect(events.first[:event]).to eq Vnet::Event::REMOVED_INTERFACE
      expect(events.first[:options][:id]).to eq interface[:id]
    end
  end
end
