# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Helpers::SecurityGroup do
  let(:instance) do
    Class.new.include(described_class).new
  end

  describe ".split_rule_collection" do
    it "returns 2 rules without comment" do
      rule = "icmp::0.0.0.0, #tcp:22,22,ip4:0.0.0.0, tcp:80:0.0.0.0 \n tcp:22:0.0.0.0"
      result = instance.split_rule_collection(rule)
      expect(result).to contain_exactly(
        "icmp::0.0.0.0",
        "tcp:22:0.0.0.0"
      )
    end

    it "returns 1 rules without comment" do
      rule = "icmp::0.0.0.0 #tcp:22,22,ip4:0.0.0.0"
      result = instance.split_rule_collection(rule)
      expect(result).to contain_exactly( "icmp::0.0.0.0")
    end

    it "returns 2 rules without comment" do
      rule = "# demo rule for demo instances\nicmp::0.0.0.0\ntcp:22:0.0.0.0"
      result = instance.split_rule_collection(rule)
      expect(result).to contain_exactly(
        "icmp::0.0.0.0",
        "tcp:22:0.0.0.0"
      )
    end
  end
end
