# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Models::Network do
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
    let!("interface#{i + 1}".to_sym) do
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
      interface
    end

    let!("route#{i + 1}".to_sym) do
      Fabricate(:route, uuid: "r-#{i + 1}", interface: send("interface#{i + 1}"))
    end

    let!("network_service#{i + 1}".to_sym) do
      Fabricate(:network_service, uuid: "ns-#{i + 1}", interface: send("interface#{i + 1}"))
    end
  end

  describe "routes" do
    subject { Vnet::Models::Network["nw-1"].routes }

    it { expect(subject.map(&:canonical_uuid)).to eq [ "r-1", "r-2", "r-3" ] }
  end

  describe "network_services" do
    subject { Vnet::Models::Network["nw-1"].network_services }

    it { expect(subject.map(&:canonical_uuid)).to eq [ "ns-1", "ns-2", "ns-3" ] }
  end
end
