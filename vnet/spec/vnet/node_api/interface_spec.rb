# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::NodeApi::Interface do
  before do
    use_mock_event_handler
  end

  describe "create" do
    it "success" do
      network = Fabricate(:network)

      interface = Vnet::NodeApi::Interface.create(
        network_id: network.id,
      )

      expect(interface[:network_id]).to eq network.id

      events = MockEventHandler.handled_events
      expect(events.size).to eq 1
      expect(events[0][:event]).to eq "network/interface_added"
      expect(events[0][:options][:network_id]).to eq network.id
      expect(events[0][:options][:interface_id]).to eq interface[:id]
    end
  end
end
