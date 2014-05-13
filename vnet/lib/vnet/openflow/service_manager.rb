# -*- coding: utf-8 -*-

module Vnet::Openflow

  class ServiceManager < Vnet::Openflow::Manager
    include Vnet::Constants::NetworkService
    include ActiveInterfaces

    #
    # Events:
    #
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

    def dns_server_for(network_id)
      @items.each do |_, item|
        next unless item.type == TYPE_DNS && item.networks[network_id]
        return item.dns_server_for(network_id)
      end
      nil
    end

    def add_dns_server(network_id, dns_server)
      @items.each do |_, item|
        next unless item.type == TYPE_DHCP && item.networks[network_id]
        item.add_dns_server(network_id, dns_server)
      end
    end

    def remove_dns_server(network_id)
      @items.each do |_, item|
        next unless item.type == TYPE_DHCP && item.networks[network_id]
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

    def match_item?(item, params)
      return false if params[:id] && params[:id] != item.id
      return false if params[:uuid] && params[:uuid] != item.uuid
      return false if params[:interface_id] && params[:interface_id] != item.interface_id

      super
    end

    def query_filter_from_params(params)
      filter = []
      filter << {id: params[:id]} if params.has_key? :id
      filter << {interface_id: params[:interface_id]} if params.has_key? :interface_id
      filter
    end

    def select_filter_from_params(params)
      return if params.has_key?(:uuid) && params[:uuid].nil?

      create_batch(mw_class.batch, params[:uuid], query_filter_from_params(params))
    end

    def item_initialize(item_map, params)
      item_class =
        case item_map.type
        when TYPE_DHCP   then Vnet::Openflow::Services::Dhcp
        when TYPE_DNS    then Vnet::Openflow::Services::Dns
        when TYPE_ROUTER then Vnet::Openflow::Services::Router
        else
          return
        end

      item_class.new(dp_info: @dp_info,
                     manager: self,
                     map: item_map)
    end

    #
    # Create / Delete events:
    #

    def item_post_install(item, item_map)
      @active_interfaces[item.interface_id].tap { |network_ids|
        next unless network_ids
        network_ids.each { |network_id|
          item.add_network_unless_exists(network_id, network_id)
        }
      }
      
      if item.type == TYPE_DNS
        if dns_service_map = MW::DnsService.batch.find(network_service_id: item.id).commit(fill: :dns_records)
          publish(SERVICE_ADDED_DNS, id: item.id, dns_service_map: dns_service_map)
        end
      end
    end    

    # item created in db on queue 'item.id'
    def created_item(params)
      return if @items[params[:id]]
      return unless @active_interfaces[params[:interface_id]]

      internal_new_item(mw_class.new(params), {})
    end

    #
    # Overload helper methods:
    #

    def activate_interface_value(interface_id, params)
      params[:network_id_list] || return
    end

    def activate_interface_update_item_proc(interface_id, params)
      network_id_list = params[:network_id_list] || return

      Proc.new { |id, item|
        network_id_list.each { |network_id|
          # TODO: Queue an event instead...
          #
          # TODO: We can't use network_id or cookie id for the cookie
          # id parameter.
          item.add_network_unless_exists(network_id, network_id)
        }
      }
    end

    #
    # Event handlers:
    #

    def set_dns_service(params)
      return unless params[:id]

      dns_service_map = params[:dns_service_map] || MW::DnsService.batch.find(id: params[:dns_service_id]).commit(fill: :dns_records)
      return unless dns_service_map

      item = @items[params[:id]] || return
      item.set_dns_service(dns_service_map)

      dns_service_map.dns_records.each do |dns_record_map|
        publish(ADDED_DNS_RECORD, id: item.id, dns_record_map: dns_record_map)
      end
    end

    def update_dns_service(params)
      dns_service_map = MW::DnsService.batch.with_deleted.first(id: params[:dns_service_id]).commit
      return unless dns_service_map

      item = @items[params[:id]] || return
      item.update_dns_service(dns_service_map)
    end

    def clear_dns_service(params)
      dns_service_map = MW::DnsService.batch.with_deleted.first(id: params[:dns_service_id]).commit
      return unless dns_service_map

      item = @items[params[:id]] || return
      item.clear_dns_service
    end

    def add_dns_record(params)
      dns_record_map = params[:dns_record_map] || MW::DnsRecord.find(id: params[:dns_record_id])
      return unless dns_record_map

      item = @items[params[:id]] || return
      item.add_dns_record(dns_record_map)
    end

    def remove_dns_record(params)
      dns_record_map = MW::DnsRecord.batch.with_deleted.first(id: params[:dns_record_id]).commit
      return unless dns_record_map

      item = @items[params[:id]] || return
      item.remove_dns_record(dns_record_map)
    end

  end

end
