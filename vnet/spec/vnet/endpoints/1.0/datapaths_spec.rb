# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'

def app
  Vnet::Endpoints::V10::VnetAPI
end

def missing_param(name, error_no)
  context "without the '#{name}' parameter" do
    it "should return a #{error_no} error" do
      happy_params.delete(name)
      post "/datapaths", happy_params
      last_response.status.should eq error_no
    end
  end
end

def required_parameters(params)
  let(:happy_params) {params}
  params.keys.each { |p| missing_param(p, 400) }
end

describe "/datapaths" do
  describe "POST /" do

    required_parameters({
      dpid: "0x0000aaaaaaaaaaaa",
      node_id: "vna1",
      display_name: "test datapath",
    })

  end
end
