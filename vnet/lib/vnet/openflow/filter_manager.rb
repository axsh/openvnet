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

      @items[GLOBAL_FILTERS_KEY] = {}
      initialize_filter(type: :accept_ingress_arp)
    end

    def initialized_item_event
      INITIALIZED_FILTER
    end

    def apply_filters(interface_hash)
      interface = interface_hash[:item_map]
      groups = interface.batch.security_groups.commit

      if groups.empty?
        debug log_format("Accepting all ingress traffic on interface '%s'" %
          interface.uuid)

        initialize_filter(type: :accept_all_traffic,
                          interface_id: interface.id)
      else
        groups.each do |group|
          debug log_format("Installing security group '%s' for interface '%s'" %
            [group.uuid, interface.uuid])

          cookie_id = group.batch.interface_cookie_id(interface.id).commit
          initialize_filter(type: :security_group,
                            id: group.id,
                            uuid: group.uuid,
                            interface_id: interface.id,
                            interface_cookie_id: cookie_id,
                            rules: group.rules)
        end
      end
    end

    def internal_detect(params)
      items = []
      @items.each { |interface_id, interface|
        items << interface[params[:id]]
      }
      items.compact
    end

    def update_item(params)
      items = internal_detect(id: params[:id])
      debug log_format("got ourselves some items")
      return nil if items.nil?

      case params[:event]
      when :update_rules
        items.each { |i|
          debug log_format("Updating rules for security group '#{i.uuid}'")
          i.update_rules(params[:rules])
        }
      when :update_isolation
        items.each { |i| i.update_isolation(params[:isolation_ips]) }
      when :update_reference
        items.each { |i| i.update_reference(params[:reference_ips]) }
      end
    end

    def remove_filters(interface_hash)
      if item = @items.delete(interface_hash[:id])
        item.each { |id, item| item.uninstall }
      end
    end

    private
    def initialize_filter(params)
      interface_id = params[:interface_id]

      item = case params[:type]
      when :accept_ingress_arp
        Filters::AcceptIngressArp.new.tap {|f| new_item(GLOBAL_FILTERS_KEY, f)}
      when :accept_all_traffic
        Filters::AcceptAllTraffic.new(interface_id)
      when :security_group
        #TODO: Send all info we need from the group wrapper in the event so
        # we don't need to make any db calls from here
        Filters::SecurityGroup.new(params)
      end

      item.dp_info = @dp_info
      new_item(interface_id, item) if interface_id

      item.install
    end

    def new_item(interface_id, item)
      @items[interface_id] ||= {}
      @items[interface_id][item.id] = item
    end
  end
end
