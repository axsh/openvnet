require 'spec_helper'

describe Vnet::Services::IpRetentionContainerManager do
  let(:manager) { described_class.new(Vnet::Services::VnetInfo.new) }
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
      manager.async.send(:load_all_items)

      3.times do |i|
        manager.wait_for_loaded({ id: i + 1 }, 1.0)
      end

      ip_retention_containers = manager.instance_variable_get(:@items)

      expect(ip_retention_containers.size).to eq 3

      ip_retention_containers.values.each do |ip_retention_container|
        expect(ip_retention_container.ip_retentions.size).to eq 3
      end
    end
  end
end
