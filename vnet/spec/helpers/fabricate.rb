# -*- coding: utf-8 -*-

def item_fabricate_with_events(manager, item_fabricator, params = {}, assoc_index = 0, assoc_fabricators = nil)
  Fabricate(item_fabricator, params).tap { |item_model|
    publish_item_created_event(manager, item_model)

    next if assoc_fabricators.nil?

    item_assoc_fabricate(assoc_fabricators, item_model, assoc_index) { |assoc_fabricator, assoc_model|
      publish_item_assoc_added_event(manager, assoc_fabricator, assoc_model)
    }
  }
end

def item_assoc_fabricators_each(assoc_fabricators, assoc_index)
  assoc_fabricators.each { |assoc_fabricator, params_list|
    params_list[assoc_index] && params_list[assoc_index].each { |assoc_params|
      yield assoc_fabricator, assoc_params
    }
  }
end

def item_assoc_fabricate(assoc_fabricators, item_model, assoc_index)
  item_assoc_fabricators_each(assoc_fabricators, assoc_index) { |assoc_fabricator, assoc_params|
    item_type = item_model.class.name.to_s.demodulize.underscore

    Fabricate(assoc_fabricator, assoc_params.merge(item_type => item_model)).tap { |assoc_model|
      yield assoc_fabricator, assoc_model
    }
  }
end
