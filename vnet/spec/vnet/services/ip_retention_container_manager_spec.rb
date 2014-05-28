require 'spec_helper'

describe Vnet::Services::IpRetentionContainerManager do
  describe "#check_lease_time_expiration" do
    it "destroy expired ip_leases" do
      pending
      current_time = Time.now

      expect(Vnet::ModelWrappers::IpLease).to receive(:expire).with(1)
      expect(Vnet::ModelWrappers::IpLease).to receive(:expire).with(2)

      manager = Vnet::Services::IpRetentionContainerManager.new(Vnet::Services::VnetInfo.new)

      manager.created_item(id: 1, ip_lease_id: 1, lease_time_expired_at: current_time - 60)
      manager.created_item(id: 2, ip_lease_id: 2, lease_time_expired_at: current_time)
      manager.created_item(id: 3, ip_lease_id: 3, lease_time_expired_at: current_time + 60)

      manager.check_lease_time_expiration
    end
  end

  describe "#check_grace_time_expiration" do
    it "destroy expired ip_retentions" do
      pending
      current_time = Time.now

      expect(Vnet::ModelWrappers::IpRetention).to receive(:destroy).with(1)
      expect(Vnet::ModelWrappers::IpRetention).to receive(:destroy).with(2)

      manager = Vnet::Services::IpRetentionManager.new(Vnet::Services::VnetInfo.new)

      manager.created_item(id: 1, ip_lease_id: 1, lease_time_expired_at: current_time - 60)
      manager.created_item(id: 2, ip_lease_id: 2, lease_time_expired_at: current_time)
      manager.created_item(id: 3, ip_lease_id: 3, lease_time_expired_at: current_time + 60)
      manager.expire_item(id: 1, grace_time_expired_at: current_time - 60)
      manager.expire_item(id: 2, grace_time_expired_at: current_time)
      manager.expire_item(id: 3, grace_time_expired_at: current_time + 60)

      manager.check_grace_time_expiration
    end
  end

  describe "load_all_items" do
    before do
      5.times do |i|
        Fabricate(:ip_retention) do
          ip_lease_id i + 1
          lease_time_expired_at Time.now + 3600
        end
      end
    end

    it "laod all database records into items" do
      pending
      manager = Vnet::Services::IpRetentionManager.new(Vnet::Services::VnetInfo.new)
      manager.load_all_items({})
      expect(manager.select.count).to eq 5
    end
  end
end
