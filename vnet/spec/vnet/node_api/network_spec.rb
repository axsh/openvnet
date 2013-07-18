# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::NodeApi::Network do
  describe "all" do
    it "return empty array" do
      ret = Vnet::NodeApi::Network.new.all
      expect(ret).to be_a Array
      expect(ret).to be_empty
    end

    it "return networks" do
      3.times.inject([]) do |array|
        array << Fabricate(:network) do
          ipv4_network { sequence(:ipv4_network, IPAddr.new("192.168.1.1").to_i) }
        end
      end
      ret = Vnet::NodeApi::Network.new.all
      expect(ret).to be_a Array
      expect(ret.size).to eq 3
      ret.each {|r| expect(r[:uuid]).to be_start_with "nw-"}
    end
  end

  describe "[]" do
    it "not found" do
      expect(Vnet::NodeApi::Network.new["nw-test"]).to be_nil
    end

    it "successfully" do
      network = Fabricate(:network)
      ret = Vnet::NodeApi::Network.new[network.canonical_uuid]
      expect(ret).to be_a Hash
      expect(ret[:uuid]).to eq network.canonical_uuid
    end
  end

  describe "update" do
    it "raise execption" do
      expect{ Vnet::NodeApi::Network.new.update("nw-test") }.to raise_error
    end

    it "successfully" do
      network = Fabricate(:network)
      ret = Vnet::NodeApi::Network.new.execute_batch(
        [:[], network.canonical_uuid],
        [:update, { :display_name => network.display_name + " updated" }]
      )

      expect(ret).to be_a Hash
      expect(ret[:uuid]).to eq network.canonical_uuid
      expect(ret[:display_name]).not_to eq network.display_name
    end
  end

  describe "destroy" do
    it "successfully" do
      network = Fabricate(:network)
      ret = Vnet::NodeApi::Network.new.execute_batch(
        [:[], network.canonical_uuid],
        [:destroy])

      expect(ret).to be_a Hash
      expect(ret[:uuid]).to eq network.canonical_uuid
      expect(network).not_to be_exists
    end
  end
end
