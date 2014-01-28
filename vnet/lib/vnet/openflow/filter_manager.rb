# -*- coding: utf-8 -*-

module Vnet::Openflow
  class FilterManager < Manager
    include Vnet::Openflow::FlowHelpers

    F = Vnet::Openflow::Filters

    subscribe_event INITIALIZED_INTERFACE, :new_interface
    subscribe_event ENABLED_FILTERING, :enable_filtering
    subscribe_event DISABLED_FILTERING, :disable_filtering
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

    def new_interface(interface_hash)
      interface = interface_hash[:item_map]
      return if is_remote?(interface)

      if interface.filters_enabled
        apply_filters(interface)
      else
        F::AcceptAllTraffic.new(interface.id, @dp_info).install
      end
    end

    def enable_filtering(interface_hash)
      interface = MW::Interface.batch[interface_hash[:id]].commit
      return if is_remote?(interface)

      debug log_format("filtering enabled for interface '%s'" % interface.uuid)

      F::AcceptAllTraffic.new(interface.id, @dp_info).uninstall
      apply_filters(interface)
    end

    def disable_filtering(interface_hash)
      interface = MW::Interface.batch[interface_hash[:id]].commit
      return if is_remote?(interface)

      debug log_format("filtering disabled for interface '%s'" % interface.uuid)

      remove_filters(interface_hash)
      F::AcceptAllTraffic.new(interface.id, @dp_info).install
    end

    def apply_filters(interface)
      groups = interface.batch.security_groups.commit
      groups.each do |group|
        item = item_by_params(id: group.id)
        item.dp_info = @dp_info

        debug log_format("Adding interface '%s' to security group '%s'" %
          [interface.uuid, item.uuid])

        cookie_id = group.batch.interface_cookie_id(interface.id).commit
        item.add_interface(interface.id, cookie_id)
        item.install(interface.id)
      end
    end

    def is_remote?(interface)
      interface.owner_datapath_id && interface.owner_datapath_id != @datapath_info.id
    end

    def select_item(filter)
      MW::SecurityGroup.batch[filter].commit
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
      interface_id = interface_hash[:id]

      items_for_interface(interface_id).each { |item|
        item.uninstall(interface_id)
        item.remove_interface(interface_id)
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
