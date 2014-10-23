# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Helpers::SecurityGroup do
  class TestClass
    include Vnet::Helpers::SecurityGroup
  end

  describe "#split_multiline_rules_string" do

    subject do
      TestClass.new.split_multiline_rules_string(rules)
    end

    context "with a comment after a valid rule on the same line and another valid rule on the next line" do
      let(:rules) do
        "icmp::0.0.0.0, #tcp:22,22,ip4:0.0.0.0, tcp:80:0.0.0.0
         tcp:22:0.0.0.0"
      end

      it "returns the rule before the comment and the one on the next line" do
        expect(subject).to contain_exactly("icmp::0.0.0.0", "tcp:22:0.0.0.0")
      end
    end

    context "with a comment after a valid rule on the same line" do
      let(:rules) { "icmp::0.0.0.0 #tcp:22,22,ip4:0.0.0.0" }

      it "returns the rule before the comment" do
        expect(subject).to contain_exactly( "icmp::0.0.0.0")
      end
    end

    context "with a comment line first and then two lines with valid comments" do
      let(:rules) do
        "# demo rule for demo instances
        icmp::0.0.0.0
        tcp:22:0.0.0.0"
      end

      it "returns the two valid rules" do
        expect(subject).to contain_exactly("icmp::0.0.0.0", "tcp:22:0.0.0.0")
      end
    end
  end
end
