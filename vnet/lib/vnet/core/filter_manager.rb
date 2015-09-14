# -*- coding: utf-8 -*-

module Vnet::Core

  class FilterManager < Vnet::Core::Manager
    include Vnet::Openflow::FlowHelpers

    subscribe_event UPDATED_SG_RULES, :updated_sg_rules
    subscribe_event UPDATED_SG_IP_ADDRESSES, :updated_sg_ip_addresses
    subscribe_event ADDED_INTERFACE_TO_SG, :added_interface_to_sg
    subscribe_event REMOVED_INTERFACE_FROM_SG, :removed_interface_from_sg
    subscribe_event REMOVED_SECURITY_GROUP, :removed_security_group

    def initialize(*args)
      super(*args)

      accept_ingress_arp.install
    end

    #
    # Event handling
    #

    def updated_sg_rules(params)
      item = internal_detect(id: params[:id])
      return if item.nil?

      info log_format("Updating rules for security group '#{item.uuid}'")
      item.update_rules(params[:rules])
    end

    def updated_sg_ip_addresses(params)
      update_referencees(params[:id], params[:ip_addresses])

      item = internal_detect(id: params[:id]) || return
      updated_isolation(item, params[:ip_addresses])
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
    end

    def added_interface_to_sg(params)
      item = internal_detect(id: params[:id]) || return

      interface = MW::Interface.batch[params[:interface_id]].commit
      if !is_remote?(interface) && interface.ingress_filtering_enabled
        log_interface_added(interface.uuid, item.uuid)

        item.add_interface(params[:interface_id], params[:interface_cookie_id])
        item.install(params[:interface_id])
      end
    end

    def removed_security_group(params)
      remove_referencee(params[:id])

      item = @items.delete(params[:id]) || return

      info log_format("removing security group", item.uuid)
      item.uninstall
    end

    #
    # The rest
    #

    def remove_referencee(id)
      @items.values.each { |i| i.remove_referencee(id) if i.references?(id) }
    end

    def update_referencees(id, ips)
      @items.values.each {|i| i.update_referencee(id, ips) if i.references?(id)}
    end

    def updated_isolation(item, ip_list)
      log_ips = ip_list.map { |i| IPAddress::IPv4.parse_u32(i).to_s }
      debug log_format("Updating isolation for security group '#{item.uuid}", log_ips)

      item.update_isolation(ip_list)
    end

    def log_interface_added(if_uuid, sg_uuid)
      debug log_format("Adding interface '%s' to security group '%s'" %
        [if_uuid, sg_uuid])
    end

    def apply_filters(interface)
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
        item = internal_retrieve(id: group.id)

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

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def mw_class
      MW::SecurityGroup
    end

    def initialized_item_event
      INITIALIZED_FILTER
    end

    # def item_unload_event
    # end

    def select_item(batch)
      batch.commit(fill: :ip_addresses)
    end

    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :uuid
        proc { |id, item| value == item.send(filter) }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter
    end

    def item_initialize(item_map)
      Filters::SecurityGroup.new(item_map).tap { |item|
        item.dp_info = @dp_info
      }
    end

    #
    # Create / Delete events:
    #

    #
    # Others:
    #

    def items_for_interface(interface_id)
      @items.values.select { |item| item.has_interface?(interface_id) }
    end

    def accept_ingress_arp
      Filters::AccepIngresstArp.new.tap {|i| i.dp_info = @dp_info}
    end

    def is_remote?(interface)
      # Need to fix this:
      active_interface = @dp_info.active_interface_manager.retrieve(interface_id: interface.id)
      active_interface.nil? || active_interface.mode == :remote
    end

  end

end
