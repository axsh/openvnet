# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Helpers::SecurityGroup do
  let(:instance) do
    Class.new.include(described_class).new
  end

  describe ".split_rule_collection" do
    let(:rule) do
      "icmp::0.0.0.0, #tcp:22,22,ip4:0.0.0.0, tcp:80:0.0.0.0 \n tcp:22:0.0.0.0"
    end

    subject { instance.split_rule_collection(rule) }

    it "returns 2 rules without comment" do
      expect(subject).to contain_exactly(
        "icmp::0.0.0.0",
        "tcp:22:0.0.0.0"
      )
    end
  end
end
