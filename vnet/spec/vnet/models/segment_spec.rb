# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Models::Segment do
  describe "destroy" do
    it "deletes associated mac_leases and mac_addresses" do
      sgm = Fabricate(:segment)
      3.times { Fabricate(:mac_lease_with_segment, segment_id: sgm.id) }

      sgm.destroy

      expect(Vnet::Models::Segment[sgm.canonical_uuid]).to eq(nil)
      expect(Vnet::Models::Segment.with_deleted.where(uuid: sgm.uuid)).not_to eq(nil)

      expect(Vnet::Models::MacLease.count).to eq(0)
      expect(Vnet::Models::MacLease.with_deleted.count).to eq(3)

      expect(Vnet::Models::MacAddress.where(segment: sgm).count).to eq(0)
      expect(Vnet::Models::MacAddress.with_deleted.where(segment: sgm).count).to eq(3)
    end

    it "deletes associated networks (and in turn, ip_leases)" do
      sgm = Fabricate(:segment)
      3.times {
        nw = Fabricate(:network, segment_id: sgm.id)
        3.times {Fabricate(:ip_lease, network_id: nw.id) }
      }

      sgm.destroy

      expect(Vnet::Models::Segment[sgm.canonical_uuid]).to eq(nil)
      expect(Vnet::Models::Segment.with_deleted.where(uuid: sgm.uuid)).not_to eq(nil)

      expect(Vnet::Models::Network.count).to eq(0)
      expect(Vnet::Models::Network.with_deleted.count).to eq(3)

      expect(Vnet::Models::IpLease.count).to eq(0)
      expect(Vnet::Models::IpLease.with_deleted.count).to eq(9)
    end
  end
end
