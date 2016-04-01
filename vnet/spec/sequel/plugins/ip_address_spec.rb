# -*- coding: utf-8 -*-
require 'spec_helper'

describe Sequel::Plugins::IpAddress do
  let(:ipv4_address_1) { IPAddress("192.168.1.2").to_i }
  let(:ipv4_address_2) { IPAddress("192.168.1.3").to_i }
  let(:ipv4_address_3) { IPAddress("192.168.2.1").to_i }
  let(:network_id_1) { Fabricate(:network, :uuid => "nw-1").id }
  let(:network_id_2) { Fabricate(:network, :uuid => "nw-2").id }
  let(:interface_id_1) { Fabricate(:interface, :uuid => "if-1").id }
  let(:interface_id_2) { Fabricate(:interface, :uuid => "if-2").id }
  let(:mac_lease_id_1) { Fabricate(:mac_lease, interface_id: interface_id_1).id }
  let(:mac_lease_id_2) { Fabricate(:mac_lease, interface_id: interface_id_2).id }

  let(:model) do
    Vnet::Models::IpLease.create(
      mac_lease_id: mac_lease_id_1,
      network_id: network_id_1,
      ipv4_address: ipv4_address_1
    )
  end

  let(:invalid_model) do
    Vnet::Models::IpLease.create(
      mac_lease_id: mac_lease_id_1,
      network_id: network_id_1,
      ipv4_address: ipv4_address_3
    )
  end

  describe "create" do
    subject do
      model
    end

    context "ip_address invalid" do
      it { expect(invalid_model).not_to be_valid }
      it { expect(subject).to be_valid }
    end

    context "ip_address association" do
      it { expect(subject.ip_address).to be_exists }
      it { expect(subject.ip_address_id).not_to be_nil }
    end

    context "ipv4_address" do
      it { expect(subject.ipv4_address).to eq ipv4_address_1 }
      it { expect(subject.to_hash[:ipv4_address]).to eq ipv4_address_1 }
      it { expect(subject.ip_address.ipv4_address).to eq ipv4_address_1 }
      it { expect(subject.reload.ipv4_address).to eq ipv4_address_1 }
    end

    context "network" do
      it { expect(subject.network_id).to eq network_id_1 }
      it { expect(subject.to_hash[:network_id]).to eq network_id_1 }
      it { expect(subject.ip_address.network.id).to eq network_id_1 }
      it { expect(subject.reload.ip_address.network.id).to eq network_id_1 }
    end

    context "mac_lease" do
      it { expect(subject.mac_lease_id).to eq mac_lease_id_1 }
      it { expect(subject.mac_lease.interface_id).to eq interface_id_1 }
      it { expect(subject.to_hash[:mac_lease_id]).to eq mac_lease_id_1 }
      it { expect(subject.reload.mac_lease_id).to eq mac_lease_id_1 }
    end

    context "interface" do
      it { expect(subject.interface_id).to eq interface_id_1 }
      it { expect(subject.to_hash[:interface_id]).to eq interface_id_1 }
      it { expect(subject.reload.interface_id).to eq interface_id_1 }
    end
  end

  describe "update" do
    subject do
      model.update(
        network_id: network_id_2,
        ipv4_address: ipv4_address_2,
        mac_lease_id: mac_lease_id_2
      )
      model
    end

    context "ip_address association" do
      it { expect(subject.ip_address).to be_exists }
      it { expect(subject.ip_address_id).not_to be_nil }
    end

    context "ipv4_address" do
      it { expect(subject.ipv4_address).to eq ipv4_address_2 }
      it { expect(subject.to_hash[:ipv4_address]).to eq ipv4_address_2 }
      it { expect(subject.ip_address.ipv4_address).to eq ipv4_address_2 }
    end

    context "network" do
      it { expect(subject.network_id).to eq network_id_2 }
      it { expect(subject.to_hash[:network_id]).to eq network_id_2 }
      it { expect(subject.ip_address.network_id).to eq network_id_2 }
      it { expect(subject.reload.ip_address.network_id).to eq network_id_2 }
    end

    context "mac_lease" do
      it { expect(subject.mac_lease_id).to eq mac_lease_id_2 }
      it { expect(subject.mac_lease.interface_id).to eq interface_id_2 }
      it { expect(subject.to_hash[:mac_lease_id]).to eq mac_lease_id_2 }
      it { expect(subject.reload.mac_lease_id).to eq mac_lease_id_2 }
    end

    context "interface" do
      it { expect(subject.interface_id).to eq interface_id_2 }
      it { expect(subject.to_hash[:interface_id]).to eq interface_id_2 }
      it { expect(subject.reload.interface_id).to eq interface_id_2 }
    end
  end

  describe "destroy" do
    it "also destroy associated ip_address model" do
      model # create model
      ip_address_count = Vnet::Models::IpAddress.count
      model.destroy
      expect(Vnet::Models::IpAddress.count).to eq ip_address_count - 1
    end
  end
end
