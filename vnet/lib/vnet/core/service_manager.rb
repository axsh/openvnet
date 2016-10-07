# -*- coding: utf-8 -*-

module Vnet::Core

  class ServiceManager < Vnet::Core::Manager
    include Vnet::Constants::NetworkService
    include ActiveInterfaceEvents

    #
    # Events:
    #
    event_handler_default_drop_all

    subscribe_event SERVICE_INITIALIZED, :load_item
    subscribe_event SERVICE_UNLOAD_ITEM, :unload_item
    subscribe_event SERVICE_CREATED_ITEM, :created_item
    subscribe_event SERVICE_DELETED_ITEM, :unload_item

    subscribe_event SERVICE_ACTIVATE_INTERFACE, :activate_interface
    subscribe_event SERVICE_DEACTIVATE_INTERFACE, :deactivate_interface

    subscribe_event SERVICE_ADDED_DNS, :set_dns_service
    subscribe_event SERVICE_REMOVED_DNS, :clear_dns_service
    subscribe_event SERVICE_UPDATED_DNS, :update_dns_service

    subscribe_event ADDED_DNS_RECORD, :add_dns_record
    subscribe_event REMOVED_DNS_RECORD, :remove_dns_record

    # TODO: Refactor these:
    def dns_server_for(network_id)
      @items.dup.each do |_, item|
        next unless item.mode == MODE_DNS.to_sym && item.networks[network_id]
        return item.dns_server_for(network_id)
      end
      nil
    end

    def add_dns_server(network_id, dns_server)
      @items.dup.each do |_, item|
        next unless item.mode == MODE_DHCP.to_sym && item.networks[network_id]
        item.add_dns_server(network_id, dns_server)
      end
    end

    def remove_dns_server(network_id)
      @items.dup.each do |_, item|
        next unless item.mode == MODE_DHCP.to_sym && item.networks[network_id]
        item.remove_dns_server(network_id)
      end
    end

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def mw_class
      MW::NetworkService
    end

    def initialized_item_event
      SERVICE_INITIALIZED
    end

    def item_unload_event
      SERVICE_UNLOAD_ITEM
    end

    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :uuid, :interface_id
        proc { |id, item| value == item.send(filter) }
      else
        raise NotImplementedError, filter
      end
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter << {interface_id: params[:interface_id]} if params.has_key? :interface_id
      filter
    end

    def item_initialize(item_map)
      item_class =
        case item_map.mode
        when MODE_DHCP   then Services::Dhcp
        when MODE_DNS    then Services::Dns
        when MODE_ROUTER then Services::Router
        else
          return
        end

      item_class.new(dp_info: @dp_info, map: item_map)
    end

    #
    # Create / Delete events:
    #

    def item_post_install(item, item_map)
      @active_interfaces[item.interface_id].tap { |params|
        if params.nil?
          debug log_format_h('item loaded while not in active_interfaces',
            id: item.id, uuid: item.uuid, interface_id: item.interface_id)
          next
        end

        segment_id_list = get_param_array(params, :segment_id_list)
        network_id_list = get_param_array(params, :network_id_list)

        network_id_list.each { |network_id|
          item.add_network_unless_exists(network_id, network_id, segment_id_list.first)
        }
      }

      if item.mode == MODE_DNS.to_sym
        load_dns_service(item)
      end

    rescue Vnet::ParamError => e
      handle_param_error(e)
    end

    # item created in db on queue 'item.id'
    def created_item(params)
      return if internal_detect_by_id(params)
      return unless @active_interfaces[params[:interface_id]]

      internal_new_item(mw_class.new(params))
    end

    #
    # Overload helper methods:
    #

    def activate_interface_value(interface_id, params)
      params || return
    end

    def activate_interface_update_item_proc(interface_id, value, params)
      segment_id_list = get_param_array(params, :segment_id_list)
      network_id_list = get_param_array(params, :network_id_list)

      Proc.new { |id, item|
        network_id_list.each { |network_id|
          # TODO: Queue an event instead...
          #
          # TODO: We can't use network_id or cookie id for the cookie
          # id parameter.
          item.add_network_unless_exists(network_id, network_id, segment_id_list.first)
        }
      }

    rescue Vnet::ParamError => e
      handle_param_error(e)
    end

    #
    # DNS:
    #

    def load_dns_service(item)
      dns_service_map = MW::DnsService.batch.find(network_service_id: item.id).commit(fill: :dns_records)
      dns_service_map && set_dns_service(id: item.id, dns_service_map: dns_service_map)
    end

    def set_dns_service(params)
      item = internal_detect_by_id(params) || return

      dns_service_map = params[:dns_service_map] || MW::DnsService.batch.find(id: params[:dns_service_id]).commit(fill: :dns_records)
      return unless dns_service_map

      item.set_dns_service(dns_service_map)

      dns_service_map.dns_records.each do |dns_record_map|
        publish(ADDED_DNS_RECORD, id: item.id, dns_record_map: dns_record_map)
      end
    end

    def update_dns_service(params)
      dns_service_map = MW::DnsService.batch.with_deleted.first(id: params[:dns_service_id]).commit
      return unless dns_service_map

      item = internal_detect_by_id(params) || return
      item.update_dns_service(dns_service_map)
    end

    def clear_dns_service(params)
      dns_service_map = MW::DnsService.batch.with_deleted.first(id: params[:dns_service_id]).commit
      return unless dns_service_map

      item = internal_detect_by_id(params) || return
      item.clear_dns_service
    end

    def add_dns_record(params)
      dns_record_map = params[:dns_record_map] || MW::DnsRecord.find(id: params[:dns_record_id])
      return unless dns_record_map

      item = internal_detect_by_id(params) || return
      item.add_dns_record(dns_record_map)
    end

    def remove_dns_record(params)
      dns_record_map = MW::DnsRecord.batch.with_deleted.first(id: params[:dns_record_id]).commit
      return unless dns_record_map

      item = internal_detect_by_id(params) || return
      item.remove_dns_record(dns_record_map)
    end

  end

end
