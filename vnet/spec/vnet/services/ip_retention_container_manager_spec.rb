# -*- coding: utf-8 -*-

require 'spec_helper'

describe Vnet::Services::IpRetentionContainerManager do

  let(:vnet_info) { Vnet::Services::VnetInfo.new }
  let(:manager) { described_class.new(vnet_info) }

  let(:item_name) { :ip_retention_container }

  describe "do_initialize" do
    # TODO: Make this work with id_sequences.
    (1..3).each { |i|
      let("item_#{i}") {
        Fabricate(item_name) do
          after_create do |item_model, _|
            3.times { Fabricate(:ip_retention, ip_retention_container: item_model) }
          end
        end
      }
    }

    let(:item_models) {
      [ item_1,
        item_2,
        item_3,
      ]
    }

    let(:item_assoc_counts) {
      { leased_ip_retentions: [3, 2, 1],
        leased_foobar: [3, 2, 1]
      }
    }

    it "load all database records into items" do
      item_models
      vnet_info.start_managers([manager])

      item_models.each { |item_model|
        expect(manager).to be_manager_with_loaded(item_model)
      }

      expect(manager).to be_manager_with_item_count(item_models.count)

      item_assoc_counts.each { |item_assoc_name, counts|
        manager.instance_variable_get(:@items).values.each_with_index { |item, item_index|
          expect(item.send(item_assoc_name).count).to eq counts[item_index]
        }
      }
    end

  end

end
