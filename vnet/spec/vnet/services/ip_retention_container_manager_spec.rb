require 'spec_helper'

describe Vnet::Services::IpRetentionContainerManager do
  describe "#check_lease_time_expiration" do
    it "expire ip_retentions whose lease time is expired" do
      current_time = Time.now

      manager = Vnet::Services::IpRetentionContainerManager.new(Vnet::Services::VnetInfo.new)

      manager.created_item(id: 1, lease_time: 1000, grace_time: 1000)

      manager.added_ip_retention(id: 1, ip_retention_id: 1, ip_lease_id: 1, lease_time_expired_at: current_time + 1000)
      manager.added_ip_retention(id: 1, ip_retention_id: 2, ip_lease_id: 2, lease_time_expired_at: current_time + 2000)

      # exceed 1000 seconds
      allow(Time).to receive(:now).and_return(current_time + 1000)
      expect(Vnet::ModelWrappers::IpLease).to receive(:expire).with(1)

      manager.check_lease_time_expiration(id: 1)

      ip_retention_container = manager.instance_variable_get(:@items)[1]
      expect(ip_retention_container.ip_retentions[1].grace_time_expired_at).to eq current_time + 1000 + 1000

      # exceed 2000 seconds
      allow(Time).to receive(:now).and_return(current_time + 2000)
      expect(Vnet::ModelWrappers::IpLease).to receive(:expire).with(2)

      manager.check_lease_time_expiration(id: 1)

      ip_retention_container = manager.instance_variable_get(:@items)[1]
      expect(ip_retention_container.ip_retentions[2].grace_time_expired_at).to eq current_time + 2000 + 1000
    end
  end

  describe "#check_grace_time_expiration" do
    it "destroy ip_retentions whose grace time is expired" do
      current_time = Time.now

      manager = Vnet::Services::IpRetentionContainerManager.new(Vnet::Services::VnetInfo.new)

      manager.created_item(id: 1, lease_time: 1000, grace_time: 1000)

      manager.added_ip_retention(id: 1, ip_retention_id: 1, ip_lease_id: 1, lease_time_expired_at: current_time)
      manager.added_ip_retention(id: 1, ip_retention_id: 2, ip_lease_id: 2, lease_time_expired_at: current_time + 1000)
      expect(Vnet::ModelWrappers::IpLease).to receive(:expire).with(1)
      manager.check_lease_time_expiration(id: 1)

      # exceed 1000 seconds
      allow(Time).to receive(:now).and_return(current_time + 1000)
      expect(Vnet::ModelWrappers::IpRetentionContainer).to receive(:remove_ip_retention).with(id: 1, ip_retention_id: 1)

      manager.check_grace_time_expiration(id: 1)

      ip_retention_container = manager.instance_variable_get(:@items)[1]
      expect(ip_retention_container.ip_retentions[1]).to be_nil

      expect(Vnet::ModelWrappers::IpLease).to receive(:expire).with(2)
      manager.check_lease_time_expiration(id: 1)

      # exceed 2000 seconds
      allow(Time).to receive(:now).and_return(current_time + 2000)
      expect(Vnet::ModelWrappers::IpRetentionContainer).to receive(:remove_ip_retention).with(id: 1, ip_retention_id: 2)

      manager.check_grace_time_expiration(id: 1)

      ip_retention_container = manager.instance_variable_get(:@items)[1]
      expect(ip_retention_container.ip_retentions[2]).to be_nil
    end
  end

  describe "load_all_items" do
    before do
      3.times do
        Fabricate(:ip_retention_container) do
          after_create do |ip_retention_container, _|
            3.times { Fabricate(:ip_retention, ip_retention_container_id: ip_retention_container.id) }
          end
        end
      end
    end

    it "laod all database records into items" do
      manager = Vnet::Services::IpRetentionContainerManager.new(Vnet::Services::VnetInfo.new)
      manager.load_all_items({})

      ip_retention_containers = manager.instance_variable_get(:@items)
      expect(ip_retention_containers.size).to eq 3
      ip_retention_containers.values.each do |ip_retention_container|
        expect(ip_retention_container.ip_retentions.size).to eq 3
      end
    end
  end
end
