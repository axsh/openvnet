# -*- coding: utf-8 -*-

ITEM_CREATED_EVENTS = {
  'Vnet::Models::IpRetentionContainer' => Vnet::Event::IP_RETENTION_CONTAINER_CREATED_ITEM,
  'Vnet::Models::Topology' => Vnet::Event::TOPOLOGY_CREATED_ITEM,
}

ITEM_DELETED_EVENTS = {
  'Vnet::Models::IpRetentionContainer' => Vnet::Event::IP_RETENTION_CONTAINER_DELETED_ITEM,
  'Vnet::Models::Topology' => Vnet::Event::TOPOLOGY_DELETED_ITEM,
}

ITEM_ASSOC_ADDED_EVENTS = {
  'Vnet::Services::TopologyManager' => {
    topology_network: Vnet::Event::TOPOLOGY_ADDED_NETWORK,
  },
}

ITEM_ASSOC_PARENT_ID_NAMES = {
  'Vnet::Services::TopologyManager' => :topology_id,
}

def publish_item_created_event(manager, item_model)
  ITEM_CREATED_EVENTS[item_model.class.name].tap { |event_name|
    if event_name.nil?
      throw "publish_item_created_event received unsupported class type '#{item_model.class.name}'"
    end

    manager.publish(event_name, item_model.to_hash)
  }
end

def publish_item_deleted_event(manager, item_model)
  ITEM_DELETED_EVENTS[item_model.class.name].tap { |event_name|
    if event_name.nil?
      throw "publish_item_deleted_event received unsupported class type '#{item_model.class.name}'"
    end

    manager.publish(event_name, id: item_model.id)
  }
end

def publish_item_assoc_added_event(manager, assoc_fabricator, assoc_model)
  [ ITEM_ASSOC_ADDED_EVENTS[manager.class.name],
    ITEM_ASSOC_PARENT_ID_NAMES[manager.class.name]
  ].tap { |assoc_events, parent_id_name|
    (assoc_events && assoc_events[assoc_fabricator]).tap { |event_name|
      if event_name.nil? || parent_id_name.nil?
        throw "publish_item_assoc_added_event received unsupported class type '#{manager.class.name}' '#{assoc_fabricator}'"
      end

      assoc_map = assoc_model.to_hash
      assoc_map[:id] = assoc_map.delete(parent_id_name)

      manager.publish(event_name, assoc_map)
    }
  }
end
