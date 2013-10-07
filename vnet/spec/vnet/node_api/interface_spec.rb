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
        network_uuid: network.canonical_uuid,
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
      expect(events[0][:event]).to eq "network/interface_added"
      expect(events[0][:options][:network_id]).to eq network.id
      expect(events[0][:options][:interface_id]).to eq interface[:id]
    end
  end

  describe "update" do
    it "with associations" do
      network_old = Fabricate(:network)
      network_new = Fabricate(:network)
      datapath = Fabricate(:datapath)

      interface = Fabricate(:interface) do
        ip_leases(count: 1) do
          Fabricate(:ip_lease) do
            network_uuid network_old.canonical_uuid
            ip_address do
              Fabricate(:ip_address) do
                ipv4_address 1
              end
            end
          end
        end
        mac_leases(count: 1) do
          Fabricate(:mac_lease) do
            mac_address 2
          end
        end
        owner_datapath datapath
      end

      Vnet::NodeApi::Interface.execute(:update,
        interface.canonical_uuid,
        {
          network_uuid: network_new.canonical_uuid,
          ipv4_address: 2,
          mac_address: 3,
        }  
      )

      model = Vnet::Models::Interface[interface.id]
      expect(model.network.id).to eq network_new.id
      expect(model.ipv4_address).to eq 2
      expect(model.mac_address).to eq 3

      #events = MockEventHandler.handled_events
      #expect(events.size).to eq 1
      #expect(events[0][:event]).to eq "network/interface_added"
      #expect(events[0][:options][:network_id]).to eq network.id
      #expect(events[0][:options][:interface_id]).to eq interface[:id]
    end
  end
end
