# -*- coding: utf-8 -*-

require 'spec_helper'

describe "vnctl datapath" do
  describe "add" do
    it "adds a new datapath" do
      args = "datapath add --uuid dp-test --open_flow_controller_uuid ofc-test " +
        "--display_name test_datapath --is-connected --dc_segment_id ds-test " +
        "--node-id some_node --ipv4_address 10.0.0.1 --dpid 0x4e6d2b508f4c"

      res = vnctl(args)

      res["uuid"].should eq("dp-test")
      res["open_flow_controller_uuid"].should eq("ofc-test")
      res["display_name"].should eq("test_datapath")
      res["is-connected"].should be_true
      res["dc_segment_id"].should eq("ds-test")
      res["node-id"].should eq("some_node")
      res["ipv4_address"].should eq(167772161)
      res["dpid"].should eq("0x4e6d2b508f4c")
    end
  end
end
