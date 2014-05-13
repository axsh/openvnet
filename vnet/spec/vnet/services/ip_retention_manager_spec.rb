require 'spec_helper'

describe Vnet::Services::IpRetentionManager do
  describe "#release_expired" do
    it "release expired items" do
      current_time = Time.now

      expect(Vnet::ModelWrappers::IpLease).to receive(:destroy).with(1)
      expect(Vnet::ModelWrappers::IpLease).to receive(:destroy).with(2)

      manager = Vnet::Services::IpRetentionManager.new(Vnet::Services::VnetInfo.new)

      manager.create_item(id: 1, ip_lease_id: 1, expired_at: current_time - 60)
      manager.create_item(id: 2, ip_lease_id: 2, expired_at: current_time)
      manager.create_item(id: 3, ip_lease_id: 3, expired_at: current_time + 60)

      manager.release_expired
    end
  end
end
