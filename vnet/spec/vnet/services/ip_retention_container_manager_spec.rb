# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }

describe Vnet::Services::IpRetentionContainerManager do
  let(:vnet_info) { Vnet::Services::VnetInfo.new }
  let(:manager) { described_class.new(vnet_info) }

  let(:item_name) { :ip_retention_container }

  (1..3).each { |index|
    let("item_#{index}") {
      Fabricate(item_name).tap { |item_model|
        (index - 1).times {
          Fabricate(:ip_retention, item_name => item_model)
        }

        publish_item_created_event(manager, item_model)
      }
    }
  }

  let(:item_models) {
    (1..3).map { |index| send("item_#{index}") }
  }

  let(:item_assoc_counts) {
    { leased_ip_retentions: [0, 1, 2],
    }
  }

  describe "create items" do
    include_examples 'create items on service manager'
  end

  describe "delete items" do
    item_names = (1..3).map { |index| "item_#{index}" }

    # TODO: Make helper method for permutations of true/false.
    [false, true].repeated_permutation(item_names.size).each { |permutation|
      context "#{permutation_context(permutation, item_names)}" do

        it "after do_initialize" do
          vnet_info.start_managers([manager])

          item_models.each { |item_model|
            expect(manager).to be_manager_with_loaded(item_model)
          }

          item_models.each_with_index { |item_model, item_index|
            next if !permutation[item_index]
            item_model.destroy
            publish_item_deleted_event(manager, item_model)
          }

          expect(manager).to be_manager_with_item_count(permutation.count(false))

          item_models.each_with_index { |item_model, item_index|
            if permutation[item_index]
              expect(manager).to be_manager_with_unloaded(item_model)
            else
              expect(manager).to be_manager_with_loaded(item_model)
            end
          }
        end

      end
    }
  end

end
