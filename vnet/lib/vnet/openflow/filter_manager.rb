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

      @items[GLOBAL_FILTERS_KEY] = []
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

          initialize_filter(type: :security_group,
                            interface_id: interface.id,
                            group_wrapper: group)
        end
      end
    end

    def update_item(params)
      debug log_format("Implement the freaking internal_detect first, you ape!")
      return nil
      # There will be multiple interfaces with this security group. We need to
      # get the references of all items that represent the updated group
      # ... Or We need to change the contents of @items
      items = internal_detect(id: id)
      return nil if item.nil?

      case params[:event]
      when :update_rules
        items.each { |i| i.update_rules(params[:rules]) }
      when :update_isolation
        items.each { |i| i.update_isolation(params[:isolation_ips]) }
      when :update_reference
        items.each { |i| i.update_reference(params[:reference_ips]) }
      end
    end

    def remove_filters(interface_hash)
      if item = @items.delete(interface_hash[:id])
        item.each { |item| @dp_info.del_cookie item.cookie }
      end
    end

    private
    def initialize_filter(params)
      interface_id = params[:interface_id]

      item = case params[:type]
      when :accept_ingress_arp
        Filters::AcceptIngressArp.new.tap {|f| @items[GLOBAL_FILTERS_KEY] << f}
      when :accept_all_traffic
        Filters::AcceptAllTraffic.new(interface_id)
      when :security_group
        Filters::SecurityGroup.new(params[:group_wrapper], interface_id)
      end

      if interface_id
        @items[interface_id] ||= []
        @items[interface_id] << item
      end

      @dp_info.add_flows item.install
    end
  end
end
