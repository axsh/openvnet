# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Models::Interface do

  let(:network) { Fabricate(:network) }
  let(:ipv4_address) { random_ipv4_i }
  let(:interface) { Fabricate(:interface) }
  let(:mac_lease) { Fabricate(:mac_lease, interface: interface) }
  let(:ip_address) { Fabricate(:ip_address,
                               network_id: network.id,
                               ipv4_address: ipv4_address) }
  let(:ip_lease) { Fabricate(:ip_lease,
                             uuid: "il-test",
                             mac_lease: mac_lease,
                             ip_address: ip_address)}

  it "delete with paranoia" do
    expect(ip_lease.deleted_at).to be_nil

    ip_lease.destroy

    expect(ip_lease.deleted_at).to be_a Time
    expect(Vnet::Models::IpLease["il-test"]).to be_nil
    expect(Vnet::Models::IpLease.count).to eq 0
    expect(Vnet::Models::IpLease.with_deleted.count).to eq 1
    expect(Vnet::Models::IpAddress[ip_address.id]).to be_nil
  end
end
