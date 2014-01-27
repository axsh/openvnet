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
          item = item_by_params(id: group.id)
          item.dp_info = @dp_info
          item.install
        end
      end
    end

    def select_item(filter)
      MW::SecurityGroup.batch[filter].commit(fill: :interface_cookie_ids)
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
      # if item = @items.delete(interface_hash[:id])
      #   item.each { |id, item| item.uninstall }
      # end
    end

    private
    def item_initialize(item_map)
      Filters::SecurityGroup.new(item_map)
    end

    #TODO: Get rid of this method
    def initialize_filter(params)
      interface_id = params[:interface_id]

      item = case params[:type]
      when :accept_ingress_arp
        Filters::AcceptIngressArp.new.tap {|f| new_item(GLOBAL_FILTERS_KEY, f)}
      when :accept_all_traffic
        Filters::AcceptAllTraffic.new(interface_id)
      when :security_group
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
