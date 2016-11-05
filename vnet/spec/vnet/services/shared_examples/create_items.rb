# -*- coding: utf-8 -*-

shared_examples 'create items on service manager' do

  [:before, :after].each { |create_when|
    it "#{create_when} do_initialize" do
      case create_when
      when :before
        item_models
      when :after
      else
        raise "Invalid create_when '#{create_when.inspect}'"
      end

      expect(manager).to be_manager_with_event_handler_state(:drop_all)
      expect(manager).to be_manager_with_no_events
      expect(manager).to be_manager_with_item_count(0)

      vnet_info.start_managers([manager])

      item_models.each { |item_model|
        expect(manager).to be_manager_with_loaded(item_model)
      }

      expect(manager).to be_manager_with_item_count(item_models.count)

      item_assoc_counts.each { |item_assoc_name, counts|
        expect(manager).to be_manager_assocs_with_item_assoc_counts(item_assoc_name, counts)
      }
    end
  }

end
