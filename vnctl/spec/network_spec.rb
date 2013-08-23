# -*- coding: utf-8 -*-

require 'spec_helper'

describe "vnctl network" do
  describe "add" do
    it "adds a new network without setting a dc network for it" do
      args = "network add --uuid nw-test --display_name test_network " +
        "--ipv4_network 10.0.0.0 --ipv4_prefix 8 --domain_name test_dns " +
        "--network-mode virtual --editable"

      res = vnctl(args)

      res["uuid"].should eq("nw-test")
      res["display_name"].should eq("test_network")
      res["ipv4_network"].should eq(167772160)
      res["ipv4_prefix"].should eq(8)
      res["domain_name"].should eq("test_dns")
      res["network_mode"].should eq("virtual")
      res["editable"].should be_true
    end

    it "raises an error when trying to add an unexistant dc network to a new network" do
      args = "network add --uuid nw-dctest --display_name test_network_for_dc " +
        "--ipv4_network 10.0.0.0 --ipv4_prefix 8 --domain_name test_dns " +
        "--dc_network_uuid dcn-dummy --network-mode virtual --editable"

      res = vnctl(args)

      res.should eq({
        "error"=>"Vnet::Endpoints::Errors::UnknownUUIDResource",
        "message"=>"dcn-dummy",
        "code"=>"100"
      })
    end

    it "adds a new network and sets a dc network for it" do
      args = "network add --uuid nw-dctest --display_name test_network_for_dc " +
        "--ipv4_network 10.0.0.0 --ipv4_prefix 8 --domain_name test_dns " +
        "--dc_network_uuid dcn-dummy --network-mode virtual --editable"

      res = vnctl(args)

      res["uuid"].should eq("nw-dctest")
      res["display_name"].should eq("test_network_for_dc")
      res["ipv4_network"].should eq(167772160)
      res["ipv4_prefix"].should eq(8)
      res["domain_name"].should eq("test_dns")
      res["dc_network_uuid"].should eq("dcn-dummy")
      res["network_mode"].should eq("virtual")
      res["editable"].should be_true
    end
  end

  describe "del" do
    it "deletes an existing network" do
      res = vnctl("network del nw-test")
      res["uuid"].should eq("nw-test")

      #TODO: Test if it's really deleted from the database
    end

    it "raises an error when trying to delete an unexisting network" do
      vnctl("network del nw-nothere").should eq({
        "error" => "Vnet::Endpoints::Errors::UnknownUUIDResource",
        "message" => "nw-nothere",
        "code" => "100"
      })
    end
  end
end
