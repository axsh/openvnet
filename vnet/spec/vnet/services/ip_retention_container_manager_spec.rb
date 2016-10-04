# -*- coding: utf-8 -*-

require 'spec_helper'

describe Vnet::Services::IpRetentionContainerManager do

  let(:vnet_info) { Vnet::Services::VnetInfo.new }
  let(:manager) { described_class.new(vnet_info) }

  describe "do_initialize" do
    # TODO: Refactor each into let's.

    before(:each) {
      3.times do
        Fabricate(:ip_retention_container) do
          after_create do |ip_retention_container, _|
            3.times { Fabricate(:ip_retention, ip_retention_container_id: ip_retention_container.id) }
          end
        end
      end
    }

    it "load all database records into items" do
      vnet_info.start_managers([manager])

      3.times { |i|
        manager.wait_for_loaded({ id: i + 1 }, 1.0)
      }

      ip_retention_containers = manager.instance_variable_get(:@items)

      expect(ip_retention_containers.size).to eq 3

      ip_retention_containers.values.each { |ip_retention_container|
        expect(ip_retention_container.leased_ip_retentions.size).to eq 3
      }
    end

  end

end
