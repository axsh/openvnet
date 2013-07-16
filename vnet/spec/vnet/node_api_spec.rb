# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::NodeApi do
  describe "get_proxy" do
    let(:conf) do
      double(:conf)
    end

    it "raise unknown proxy error" do
      conf.stub(:node_api_proxy).and_return(:aaa)
      expect { Vnet::NodeApi.get_proxy(conf) }.to raise_error "Unknown proxy: aaa"
    end

    it "return dba proxy" do
      conf.stub(:node_api_proxy).and_return(:rpc)
      expect(Vnet::NodeApi.get_proxy(conf)).to be_a Vnet::NodeApi::RpcProxy
    end

    it "return direct proxy" do
      conf.stub(:node_api_proxy).and_return(:direct)
      expect(Vnet::NodeApi.get_proxy(conf)).to be_a Vnet::NodeApi::DirectProxy
    end
  end
end
