# -*- coding: utf-8 -*-

module Vnet::Openflow
  class FilterManager < Manager
    include Vnet::Openflow::FlowHelpers

    subscribe_event UPDATED_SG_RULES, :updated_filter
    subscribe_event ADDED_INTERFACE_TO_SG, :added_interface_to_sg
    subscribe_event REMOVED_INTERFACE_FROM_SG, :removed_interface_from_sg

    def initialize(*args)
      super(*args)

      accept_ingress_arp.install
    end

    #
    # Event handling
    #

    def updated_filter(params)
      item = internal_detect(id: params[:id])
      return if item.nil?

      info log_format("Updating rules for security group '#{item.uuid}'")
      item.update_rules(params[:rules])
    end

    def removed_interface_from_sg(params)
      item = internal_detect(id: params[:id]) || return

      info log_format("Removing interface '%s' from security group '%s'" %
        [params[:interface_id], item.uuid])

      if item.has_interface?(params[:interface_id])
        item.uninstall(params[:interface_id])
        item.remove_interface(params[:interface_id])

        @items.delete(item.id) if item.interfaces.empty?
      end

      updated_isolation(item, params[:isolation_ip_addresses])
    end

    def added_interface_to_sg(params)
      item = item_by_params(id: params[:id]) || return

      updated_isolation(item, params[:isolation_ip_addresses])

      unless is_remote?(params[:interface_owner_datapath_id], params[:interface_active_datapath_id])
        log_interface_added(params[:interface_id], item.uuid)

        item.add_interface(params[:interface_id], params[:interface_cookie_id])
        item.install(params[:interface_id])
      end
    end

    #
    # The rest
    #

    def removed_interface(interface_id)
      accept_all_traffic(interface_id).uninstall
      remove_filters(interface_id)
    end

    def updated_isolation(item, ip_list)
      log_ips = ip_list.map { |i| IPAddress::IPv4.parse_u32(i).to_s }
      debug log_format("Updating isolation for security group '#{item.uuid}", log_ips)

      item.update_isolation(ip_list)
    end

    def initialized_item_event
      INITIALIZED_FILTER
    end

    def log_interface_added(if_uuid, sg_uuid)
      debug log_format("Adding interface '%s' to security group '%s'" %
        [if_uuid, sg_uuid])
    end

    def apply_filters(interface)
      #TODO: Check if we can't get rid of this argument raping
      interface = case interface
      when MW::Interface
        interface
      when Numeric, String
        interface = MW::Interface.batch[interface].commit
      else
        raise "Not an interface: #{interface.inspect}"
      end

      info log_format("applying filters for interface: '#{interface.uuid}'")

      groups = interface.batch.security_groups.commit
      groups.each do |group|
        item = item_by_params(id: group.id)

        log_interface_added(interface.uuid, item.uuid)

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

    def accept_all_traffic(interface_id)
      Filters::AcceptAllTraffic.new(interface_id, @dp_info).install
    end

    def filter_traffic(interface_id)
      Filters::AcceptAllTraffic.new(interface_id, @dp_info).uninstall
    end

    private
    def select_item(filter)
      MW::SecurityGroup.batch[filter].commit(fill: :ip_addresses)
    end

    def item_initialize(item_map, params)
      Filters::SecurityGroup.new(item_map).tap { |item|
        item.dp_info = @dp_info
      }
    end

    def items_for_interface(interface_id)
      @items.values.select { |item| item.has_interface?(interface_id) }
    end

    def accept_ingress_arp
      Filters::AcceptIngressArp.new.tap {|i| i.dp_info = @dp_info}
    end
  end
end
