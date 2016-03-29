# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::ModelWrappers::RouteLink do
  let!(:nw_global) { Fabricate(:network_any, uuid: 'nw-global') }
  let!(:nw_vnet) { Fabricate(:network_any, uuid: 'nw-vnet') }

  let!(:r_global) { Fabricate(:route_any, route_link: rl, network: nw_global) } 
  let!(:r_vnet) { Fabricate(:route_any, route_link: rl, network: nw_vnet) } 

  let!(:rl) { Fabricate(:route_link) } 

  context "lookup_by_nw" do
    subject { Vnet::ModelWrappers::RouteLink }
    it "shows a route_link derived from network uuids" do
      i_uuid = nw_global.canonical_uuid
      e_uuid = nw_vnet.canonical_uuid

      expect(subject.lookup_by_nw(i_uuid, e_uuid).id).to eq rl.id
    end
  end
end
