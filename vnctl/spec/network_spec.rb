# -*- coding: utf-8 -*-

require 'spec_helper'

describe "vnctl network" do
  describe "add" do
    it "adds a new network and sets its uuid" do
      vnctl("network add --uuid nw-testnw")["uuid"].should eq("nw-testnw")
      # Delete it so we can run this test again
      vnctl("network del nw-testnw")
    end

    it "raises an error when trying to set an invalid uuid" do
      vnctl("network add --uuid testnw").should eq({
        "error" => "Vnet::Endpoints::Errors::InvalidUUID",
        "message" => "testnw",
        "code" => "101"
      })
    end

    it "adds a new network without setting a dc network nor uuid for it" do
      args = "network add --display_name test_network " +
        "--ipv4_network 10.0.0.0 --ipv4_prefix 8 --domain_name test_dns " +
        "--network-mode virtual --editable"

      res = vnctl(args)

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
      args = "network add --display_name test_network_for_dc " +
        "--ipv4_network 10.0.0.0 --ipv4_prefix 8 --domain_name test_dns " +
        "--dc_network_uuid dcn-dummy --network-mode virtual --editable"

      res = vnctl(args)

      res["display_name"].should eq("test_network_for_dc")
      res["ipv4_network"].should eq(167772160)
      res["ipv4_prefix"].should eq(8)
      res["domain_name"].should eq("test_dns")
      res["dc_network_uuid"].should eq("dcn-dummy")
      res["network_mode"].should eq("virtual")
      res["editable"].should be_true
    end
  end

  # describe "show" do
  #   it "shows multiple networks" do
  #     raise NotImplementedError
  #   end

  #   it "shows a single network" do
  #     raise NotImplementedError
  #   end

  #   it "raises an error when trying to show a nonexistant network" do
  #     raise NotImplementedError
  #   end
  # end

  describe "del" do
    it "deletes an existing network" do
      nw = vnctl("network add")["uuid"]
      res = vnctl("network del #{nw}")
      res["uuid"].should eq(nw)
    end

    it "deletes multiple existing networks" do
      nw1 = vnctl("network add")["uuid"]
      nw2 = vnctl("network add")["uuid"]
      nw3 = vnctl("network add")["uuid"]

      res = vnctl("network del #{nw1} #{nw2} #{nw3}")

      res[0]["uuid"].should eq(nw1)
      res[1]["uuid"].should eq(nw2)
      res[2]["uuid"].should eq(nw3)
    end

    it "raises an error when trying to delete an unexisting network" do
      vnctl("network del nw-nothere").should eq({
        "error" => "Vnet::Endpoints::Errors::UnknownUUIDResource",
        "message" => "nw-nothere",
        "code" => "100"
      })
    end

    it "raises an error when trying to delete a uuid with invalid syntax" do
      vnctl("network del i_am_not_quite_right").should eq({
        "error" => "Vnet::Endpoints::Errors::InvalidUUID",
        "message" => "i_am_not_quite_right",
        "code" => "101"
      })
    end
  end
end
