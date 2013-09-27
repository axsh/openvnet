# -*- coding: utf-8 -*-
require 'spec_helper'

describe Sequel::Plugins::IpAddress do
  let(:ipv4_address_1) { 1 }
  let(:ipv4_address_2) { 2 }

  let(:model) do
    Vnet::Models::IpLease.create(ipv4_address: ipv4_address_1)
  end

  describe "create" do
    subject do
      model
    end

    it { expect(subject.ipv4_address).to eq ipv4_address_1 }
    it { expect(subject.to_hash[:ipv4_address]).to eq ipv4_address_1 }
    it { expect(subject.ip_address).to be_exists }
    it { expect(subject.ip_address_id).not_to be_nil }
    it { expect(subject.ip_address.ipv4_address).to eq ipv4_address_1 }
    it { expect(subject.reload.ipv4_address).to eq ipv4_address_1 }
  end

  describe "update" do
    subject do
      model.update(ipv4_address: ipv4_address_2)
      model
    end

    it { expect(subject.ipv4_address).to eq ipv4_address_2 }
    it { expect(subject.to_hash[:ipv4_address]).to eq ipv4_address_2 }
    it { expect(subject.ip_address).to be_exists }
    it { expect(subject.ip_address_id).not_to be_nil }
    it { expect(subject.ip_address.ipv4_address).to eq ipv4_address_2 }
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
