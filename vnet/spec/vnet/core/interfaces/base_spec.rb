# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Core::Interfaces::Base do
  let(:subclass) { Class.new(Vnet::Core::Interfaces::Base) }
  let(:instance) {
    subclass.new(dp_info: MockEmptyDpInfo.new,
                 map: OpenStruct.new(id: 1, uuid: 'if-test', mode: "mode"))
  }

  describe "cookie" do
    it { expect(instance.cookie.to_s(16)).to eq "c00000000000001" }
    it { expect(instance.cookie(subclass::OPTIONAL_TYPE_TAG, subclass::TAG_ARP_REQUEST_INTERFACE).to_s(16)).to eq "c00001100000001" }
    it { expect(instance.cookie(subclass::OPTIONAL_TYPE_IP_LEASE, 3).to_s(16)).to eq "c00003200000001" }
    it { expect{instance.cookie(1 << 4)}.to raise_error(/0x10$/) }
    it { expect{instance.cookie(subclass::OPTIONAL_TYPE_IP_LEASE, 1 << 32)}.to raise_error(/0x100000000$/) }
    it { expect{instance.cookie(subclass::OPTIONAL_TYPE_IP_LEASE, -1)}.to raise_error(/0x\.\.f$/) }
  end
end
