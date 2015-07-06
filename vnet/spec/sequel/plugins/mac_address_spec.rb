# -*- coding: utf-8 -*-
require 'spec_helper'

describe Sequel::Plugins::MacAddress do
  let(:mac_address_1) { MacAddr.new("00:00:00:00:00:01").to_i }
  let(:mac_address_2) { MacAddr.new("00:00:00:00:00:02").to_i }

  context "with attr_name" do
    let(:model) do
      Vnet::Models::DatapathNetwork.create(
        :datapath_id => 1,
        :network_id => 1,
        :mac_address => mac_address_1
      )
    end

    describe "create" do
      subject do
        model
      end

      it { expect(subject.mac_address).to eq mac_address_1 }
      it { expect(subject.to_hash[:mac_address]).to eq mac_address_1 }
      it { expect(subject.mac_address).to be_exists }
      it { expect(subject.mac_address.mac_address).to eq mac_address_1 }
      it { expect(subject.reload.mac_address).to eq mac_address_1 }
    end

    describe "update" do
      subject do
        model.mac_address = mac_address_2
        model.save
      end

      it { expect(subject.mac_address).to eq mac_address_2 }
      it { expect(subject.to_hash[:mac_address]).to eq mac_address_2 }
      it { expect(subject.mac_address).to be_exists }
      it { expect(subject.mac_address.mac_address).to eq mac_address_2 }
    end

    describe "destroy" do
      it "also destroy associated mac_address object" do
        model # create model
        mac_address_count = Vnet::Models::MacAddress.count
        model.destroy
        expect(Vnet::Models::MacAddress.count).to eq mac_address_count - 1
      end
    end
  end

  context "without attr_name" do
    let(:model) do
      Vnet::Models::MacLease.create(
        :mac_address => mac_address_1
      )
    end

    describe "create" do
      subject do
        model
      end

      it { expect(subject.mac_address).to eq mac_address_1 }
      it { expect(subject.to_hash[:mac_address]).to eq mac_address_1 }
      it { expect(subject._mac_address).to be_exists }
      it { expect(subject.mac_address_id).not_to be_nil }
      it { expect(subject._mac_address.mac_address).to eq mac_address_1 }
      it { expect(subject.reload.mac_address).to eq mac_address_1 }
    end

    describe "update" do
      subject do
        model.update(mac_address: mac_address_2)
        model
      end

      it { expect(subject.mac_address).to eq mac_address_2 }
      it { expect(subject.to_hash[:mac_address]).to eq mac_address_2 }
      it { expect(subject._mac_address).to be_exists }
      it { expect(subject.mac_address_id).not_to be_nil }
      it { expect(subject._mac_address.mac_address).to eq mac_address_2 }
    end

    describe "destroy" do
      it "also destroy associated mac_address model" do
        model # create model
        mac_address_count = Vnet::Models::MacAddress.count
        model.destroy
        expect(Vnet::Models::MacAddress.count).to eq mac_address_count - 1
      end
    end
  end
end
