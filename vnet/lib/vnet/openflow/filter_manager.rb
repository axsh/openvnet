# -*- coding: utf-8 -*-

module Vnet::Openflow
  class FilterManager < Manager
    include Vnet::Openflow::FlowHelpers

    subscribe_event INITIALIZED_INTERFACE, :initialized_interface
    subscribe_event REMOVED_INTERFACE, :removed_interface
    subscribe_event ENABLED_FILTERING, :enabled_filtering
    subscribe_event DISABLED_FILTERING, :disabled_filtering
    subscribe_event UPDATED_SG_RULES, :updated_filter
    subscribe_event UPDATED_SG_ISOLATION, :updated_isolation

    def initialize(*args)
      super(*args)

      accept_ingress_arp.install
    end

    #
    # Event handling
    #

    def initialized_interface(params)
      interface = params[:item_map]
      return if is_remote?(interface.owner_datapath_id)

      if interface.enable_ingress_filtering
        apply_filters(interface)
      else
        #TODO: Bypass filtering table instead?
        accept_all_traffic(interface.id).install
      end
    end

    def removed_interface(params)
      accept_all_traffic(params[:id]).uninstall
      remove_filters(params[:id])
    end

    def enabled_filtering(params)
      return if is_remote?(params[:owner_datapath_id], params[:active_datapath_id])
      interface = MW::Interface.batch[params[:id]].commit

      debug log_format("filtering enabled for interface '%s'" % interface.uuid)

      accept_all_traffic(interface.id).uninstall
      apply_filters(interface)
    end

    def disabled_filtering(params)
      return if is_remote?(params[:owner_datapath_id], params[:active_datapath_id])

      debug log_format("filtering disabled for interface '%s'" % params[:uuid])

      remove_filters(params[:id])
      accept_all_traffic(params[:id]).install
    end

    def updated_filter(params)
      item = internal_detect(id: params[:id])
      return if item.nil?

      debug log_format("Updating rules for security group '#{item.uuid}'")
      item.update_rules(params[:rules])
    end

    def updated_isolation(params)
      item = internal_detect(id: params[:id])
      return if item.nil?

      log_ips = params[:ip_addresses].map { |i| IPAddress::IPv4.parse_u32(i).to_s }
      debug log_format("Updating isolation for security group: '#{params[:uuid]}'", log_ips)

      item.update_isolation(params[:ip_addresses])
    end

    #
    # The rest
    #

    def initialized_item_event
      INITIALIZED_FILTER
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

    def remove_filters(interface_id)
      items_for_interface(interface_id).each { |item|
        item.uninstall(interface_id)
        item.remove_interface(interface_id)
      }
    end

    def select_item(filter)
      MW::SecurityGroup.batch[filter].commit(fill: :ip_addresses)
    end

    private
    def item_initialize(item_map, params)
      Filters::SecurityGroup.new(item_map)
    end

    def items_for_interface(interface_id)
      @items.values.select { |item| item.has_interface?(interface_id) }
    end

    def accept_all_traffic(interface_id)
      Filters::AcceptAllTraffic.new(interface_id, @dp_info)
    end

    def accept_ingress_arp
      Filters::AcceptIngressArp.new.tap {|i| i.dp_info = @dp_info}
    end
  end
end
