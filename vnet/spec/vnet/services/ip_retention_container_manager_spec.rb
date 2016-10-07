# -*- coding: utf-8 -*-

require 'spec_helper'

describe Vnet::Services::IpRetentionContainerManager do

  let(:vnet_info) { Vnet::Services::VnetInfo.new }
  let(:manager) { described_class.new(vnet_info) }

  let(:item_name) { :ip_retention_container }

  describe "do_initialize" do
    (1..3).each { |index|
      let("item_#{index}") {
        Fabricate(item_name).tap { |item_model|
          index.times {
            Fabricate(:ip_retention, ip_retention_container: item_model)
          }
        }
      }
    }

    let(:item_models) {
      (1..3).map { |index| send("item_#{index}") }
    }

    let(:item_assoc_counts) {
      { leased_ip_retentions: [3, 3, 3],
      }
    }

    it "create items before do_initialize" do
      item_models
      vnet_info.start_managers([manager])

      item_models.each { |item_model|
        expect(manager).to be_manager_with_loaded(item_model)
      }

      expect(manager).to be_manager_with_item_count(item_models.count)

      item_assoc_counts.each { |item_assoc_name, counts|
        expect(manager).to be_manager_assocs_with_item_assoc_counts(item_assoc_name, counts)
      }
    end
  end

end
