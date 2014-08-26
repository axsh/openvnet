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
      if i == 3
        network = network2
      else
        network = network1
      end

      Fabricate(:route,
                uuid: "r-#{i + 1}",
                interface: send("interface#{i + 1}"),
                network: network)
    end

    let!("network_service#{i + 1}".to_sym) do
      Fabricate(
        :network_service_dhcp,
        uuid: "ns-#{i + 1}",
        interface: send("interface#{i + 1}"),
      )
    end
  end

  describe "routes" do
    subject { Vnet::Models::Network["nw-1"].routes }

    it { expect(subject.map(&:canonical_uuid)).to eq [ "r-1", "r-2", "r-3" ] }
  end

  describe "find_by_mac_address" do
    it { expect(Vnet::Models::MacAddress[mac_address: 0].mac_lease.ip_leases.first.network).to eq network1 }
    it { expect(Vnet::Models::MacAddress[mac_address: 2].mac_lease.ip_leases.first.network).to eq network1 }
    it { expect(Vnet::Models::MacAddress[mac_address: 4].mac_lease.ip_leases.first.network).to eq network1 }
    it { expect(Vnet::Models::MacAddress[mac_address: 6].mac_lease.ip_leases.first.network).to eq network2 }
  end

  describe "destroy" do
    subject {  network1.destroy }

    it "deleting a network deletes associated items" do
      expect(subject).to be_a Vnet::Models::Network

      expect(subject.ip_addresses).to be_empty
      expect(subject.datapath_networks).to be_empty
      expect(subject.routes).to be_empty
    end
  end

end
