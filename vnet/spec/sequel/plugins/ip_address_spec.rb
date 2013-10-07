# -*- coding: utf-8 -*-
require 'spec_helper'

describe Sequel::Plugins::IpAddress do
  let(:ipv4_address_1) { 1 }
  let(:ipv4_address_2) { 2 }
  let(:network_uuid_1) { Fabricate(:network, :uuid => "nw-1").canonical_uuid }
  let(:network_uuid_2) { Fabricate(:network, :uuid => "nw-2").canonical_uuid }

  let(:model) do
    Vnet::Models::IpLease.create(:network_uuid => network_uuid_1, :ipv4_address => ipv4_address_1)
  end

  describe "create" do
    subject do
      model
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

    context "network_uuid" do
      it { expect(subject.network_uuid).to eq network_uuid_1 }
      it { expect(subject.to_hash[:network_uuid]).to eq network_uuid_1 }
      it { expect(subject.ip_address.network.canonical_uuid).to eq network_uuid_1 }
      it { expect(subject.reload.ip_address.network.canonical_uuid).to eq network_uuid_1 }
    end
  end

  describe "update" do
    subject do
      model.update(network_uuid: network_uuid_2, ipv4_address: ipv4_address_2)
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

    context "network_uuid" do
      it { expect(subject.network_uuid).to eq network_uuid_2 }
      it { expect(subject.to_hash[:network_uuid]).to eq network_uuid_2 }
      it { expect(subject.ip_address.network.canonical_uuid).to eq network_uuid_2 }
      it { expect(subject.reload.ip_address.network.canonical_uuid).to eq network_uuid_2 }
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
