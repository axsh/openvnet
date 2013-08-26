# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet/endpoints/1.0/vnet_api'

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/mac_addresses" do
  describe "POST /" do
    it "create a record of mac_addresses" do
      mac_addr = random_mac
      network = Fabricate(:network)

      params = {
        mac_address: mac_addr
      }

      post "/mac_addresses", params

      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      expect(body["mac_address"]).to eq mac_addr.to_i
    end
  end
end
