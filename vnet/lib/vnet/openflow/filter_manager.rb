# -*- coding: utf-8 -*-

module Vnet::Openflow
  class FilterManager < Manager
    include Vnet::Openflow::FlowHelpers

    subscribe_event INITIALIZED_INTERFACE, :apply_filters
    subscribe_event REMOVED_INTERFACE, :remove_filters
    subscribe_event UPDATED_FILTER, :update_item

    GLOBAL_FILTERS_KEY = 'global'

    def initialize(*args)
      super(*args)

      accept_ingress_arp
    end

    def initialized_item_event
      INITIALIZED_FILTER
    end

    def apply_filters(interface_hash)
      interface = interface_hash[:item_map]
      groups = interface.batch.security_groups.commit

      groups.each do |group|
        item = item_by_params(id: group.id)
        item.dp_info = @dp_info
        item.install
      end
    end

    def select_item(filter)
      MW::SecurityGroup.batch[filter].commit(fill: :interface_cookie_ids)
    end

    def update_item(params)
      item = internal_detect(id: params[:id])
      return nil if item.nil?

      case params[:event]
      when :update_rules
        debug log_format("Updating rules for security group '#{item.uuid}'")
        item.update_rules(params[:rules])
        #TODO: Update reference as well
      when :update_isolation
        item.update_isolation(params[:isolation_ips])
      when :update_reference
        item.update_reference(params[:reference_ips])
      end
    end

    def remove_filters(interface_hash)
      items_for_interface(interface_hash[:id]).each { |item|
        item.uninstall(interface_hash[:id])
      }
    end

    private
    def item_initialize(item_map)
      Filters::SecurityGroup.new(item_map)
    end

    def items_for_interface(interface_id)
      @items.values.select { |item| item.has_interface?(interface_id) }
    end

    def accept_ingress_arp
      Filters::AcceptIngressArp.new.tap {|i| i.dp_info = @dp_info}.install
    end
  end
end
