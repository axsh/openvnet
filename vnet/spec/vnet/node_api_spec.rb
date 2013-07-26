# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::NodeApi do
  describe "get_proxy" do
    it "raise unknown proxy error" do
      expect { Vnet::NodeApi.get_proxy(:aaa) }.to raise_error "Unknown proxy: aaa"
    end

    it "return rpc proxy" do
      expect(Vnet::NodeApi.get_proxy(:rpc)).to be_a Vnet::NodeApi::RpcProxy
    end

    it "return direct proxy" do
      expect(Vnet::NodeApi.get_proxy(:direct)).to be_a Vnet::NodeApi::DirectProxy
    end
  end
end
