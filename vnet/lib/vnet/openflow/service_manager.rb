# -*- coding: utf-8 -*-

module Vnet::Openflow

  class ServiceManager < Vnet::Manager

    #
    # Events:
    #
    subscribe_event SERVICE_INITIALIZED, :install_item
    subscribe_event SERVICE_CREATED_ITEM, :created_item
    subscribe_event SERVICE_DELETED_ITEM, :unload_item

    subscribe_event SERVICE_ACTIVATE_INTERFACE, :activate_interface
    subscribe_event SERVICE_DEACTIVATE_INTERFACE, :deactivate_interface

    subscribe_event SERVICE_ADDED_DNS, :set_dns_service
    subscribe_event SERVICE_REMOVED_DNS, :clear_dns_service
    subscribe_event SERVICE_UPDATED_DNS, :update_dns_service

    subscribe_event ADDED_DNS_RECORD, :add_dns_record
    subscribe_event REMOVED_DNS_RECORD, :remove_dns_record

    def initialize(*args)
      super

      @active_interfaces = {}
    end

    def dns_server_for(network_id)
      @items.each do |_, item|
        next unless item.type == "dns" && item.networks[network_id]
        return item.dns_server_for(network_id)
      end
      nil
    end

    def add_dns_server(network_id, dns_server)
      @items.each do |_, item|
        next unless item.type == "dhcp" && item.networks[network_id]
        item.add_dns_server(network_id, dns_server)
      end
    end

    def remove_dns_server(network_id)
      @items.each do |_, item|
        next unless item.type == "dhcp" && item.networks[network_id]
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

    def initialized_item_event
      SERVICE_INITIALIZED
    end

    def match_item?(item, params)
      return false if params[:id] && params[:id] != item.id
      return false if params[:uuid] && params[:uuid] != item.uuid
      return false if params[:interface_id] && params[:interface_id] != item.interface_id

      super
    end

    def select_filter_from_params(params)
      return nil if params.has_key?(:uuid) && params[:uuid].nil?

      filters = []
      filters << {id: params[:id]} if params.has_key? :id
      filters << {interface_id: params[:interface_id]} if params.has_key? :interface_id

      create_batch(MW::NetworkService.batch, params[:uuid], filters)
    end

    def item_initialize(item_map, params)
      item_class =
        case item_map.type
        when 'dhcp'   then Vnet::Openflow::Services::Dhcp
        when 'dns'    then Vnet::Openflow::Services::Dns
        when 'router' then Vnet::Openflow::Services::Router
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

    # SERVICE_INITIALIZED on queue 'item.id'
    def install_item(params)
      item_map = params[:item_map] || return
      item = (item_map.id && @items[item_map.id]) || return

      debug log_format("install #{item_map.uuid}/#{item_map.id}", "mode:#{item_map.type.to_sym}")

      item.try_install

      if item.type == "dns"
        if dns_service_map = MW::DnsService.batch.find(network_service_id: item.id).commit(fill: :dns_records)
          publish(SERVICE_ADDED_DNS, id: item.id, dns_service_map: dns_service_map)
        end
      end
    end    

    # item created in db on queue 'item.id'
    def created_item(params)
      return if @items[params[:id]]
      return unless @active_interfaces[params[:interface_id]]

      internal_new_item(MW::NetworkService.new(params), {})
    end

    # unload item on queue 'item.id'
    def unload_item(params)
      item = @items.delete(params[:id]) || return
      item.try_uninstall

      debug log_format("unloaded service #{item.uuid}/#{item.id}")
    end

    #
    # Event handlers:
    #

    def set_dns_service(params)
      return unless params[:id]

      dns_service_map = params[:dns_service_map] || MW::DnsService.batch.find(id: params[:dns_service_id]).commit(fill: :dns_records)
      return unless dns_service_map

      item = @items[params[:id]]
      return unless item

      item.set_dns_service(dns_service_map)

      dns_service_map.dns_records.each do |dns_record_map|
        publish(ADDED_DNS_RECORD, id: item.id, dns_record_map: dns_record_map)
      end
    end

    def update_dns_service(params)
      dns_service_map = MW::DnsService.batch.with_deleted.first(id: params[:dns_service_id]).commit
      return unless dns_service_map

      item = @items[params[:id]]
      return unless item

      item.update_dns_service(dns_service_map)
    end

    def clear_dns_service(params)
      dns_service_map = MW::DnsService.batch.with_deleted.first(id: params[:dns_service_id]).commit
      return unless dns_service_map

      item = @items[params[:id]]
      return unless item

      item.clear_dns_service
    end

    def add_dns_record(params)
      dns_record_map = params[:dns_record_map] || MW::DnsRecord.find(id: params[:dns_record_id])
      return unless dns_record_map

      item = @items[params[:id]]
      return unless item

      item.add_dns_record(dns_record_map)
    end

    def remove_dns_record(params)
      dns_record_map = MW::DnsRecord.batch.with_deleted.first(id: params[:dns_record_id]).commit
      return unless dns_record_map

      item = @items[params[:id]]
      return unless item

      item.remove_dns_record(dns_record_map)
    end

    #
    # Interface events:
    #

    # SERVICE_ACTIVATE_INTERFACE on queue ':interface'
    def activate_interface(params)
      interface_id = params[:interface_id] || return
      return if @active_interfaces[interface_id]

      @active_interfaces[interface_id] = true

      item_maps = MW::NetworkService.batch.where(interface_id: interface_id).all.commit
      item_maps.each { |item_map| internal_new_item(item_map, {}) }
    end

    # SERVICE_DEACTIVATE_INTERFACE on queue ':interface'
    def deactivate_interface(params)
      # return if params[:interface_id].nil?
      # routes = @active_interfaces.delete(params[:interface_id]) || return

    end

  end

end
