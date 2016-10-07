# -*- coding: utf-8 -*-

shared_examples 'create items on service manager' do
  it "before do_initialize" do
    item_models

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

  it "after do_initialize" do
    expect(manager).to be_manager_with_event_handler_state(:drop_all)

    vnet_info.start_managers([manager])

    expect(manager).to be_manager_with_no_events
    expect(manager).to be_manager_with_item_count(0)

    item_models.each { |item_model|
      expect(manager).to be_manager_with_loaded(item_model)
    }

    expect(manager).to be_manager_with_item_count(item_models.count)

    item_assoc_counts.each { |item_assoc_name, counts|
      expect(manager).to be_manager_assocs_with_item_assoc_counts(item_assoc_name, counts)
    }
  end
end
