# -*- coding: utf-8 -*-

ITEM_CREATED_EVENTS = {
  'Vnet::Models::IpRetentionContainer' => Vnet::Event::IP_RETENTION_CONTAINER_CREATED_ITEM
}

def publish_item_created_event(manager, item_model)
  ITEM_CREATED_EVENTS[item_model.class.name].tap { |event_name|
    if event_name.nil?
      throw "publish_item_created_event received unsupported class type '#{item_model.class.name}'"
    end

    manager.publish(event_name, item_model.to_hash)
  }
end
