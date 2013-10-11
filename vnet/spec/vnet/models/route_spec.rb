# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Models::Route do
  describe "on_other_networks" do
    let(:network1) do
      Fabricate(:network,
              uuid: "nw-1",
              ipv4_network: IPAddr.new("10.101.1.0").to_i,
              ipv4_prefix: 24)
    end

    let(:network2) do
      Fabricate(:network,
              uuid: "nw-2",
              ipv4_network: IPAddr.new("10.102.1.0").to_i,
              ipv4_prefix: 24)
    end

    let(:ipv4_address1) { IPAddr.new("10.101.1.10").to_i }
    let(:ipv4_address2) { IPAddr.new("10.102.1.10").to_i }

    4.times do |i|
      let!("route#{i + 1}".to_sym) do
        if i == 3
          network = network2
          ipv4_address = ipv4_address2
        else
          network = network1
          ipv4_address = ipv4_address1 + i
        end
        interface = Fabricate(:interface)
        mac_lease = Fabricate(:mac_lease, interface: interface)
        ip_lease = Fabricate(:ip_lease,
                             mac_lease_id: mac_lease.id,
                             network_id: network.id,
                             ipv4_address: ipv4_address)
        Fabricate(:route, interface: interface)
      end
    end

    subject { route1.on_other_networks(network1.id) }

    it { expect(subject).to eq [ route2, route3 ] }
  end
end
