# -*- coding: utf-8 -*-

module Vnet::Openflow

  class ServiceManager < Vnet::Manager

    #
    # Events:
    #
    subscribe_event ADDED_SERVICE, :item
    subscribe_event REMOVED_SERVICE, :unload
    subscribe_event INITIALIZED_SERVICE, :create_item
    subscribe_event ADDED_DNS_SERVICE, :set_dns_service
    subscribe_event REMOVED_DNS_SERVICE, :clear_dns_service
    subscribe_event UPDATED_DNS_SERVICE, :update_dns_service
    subscribe_event ADDED_DNS_RECORD, :add_dns_record
    subscribe_event REMOVED_DNS_RECORD, :remove_dns_record

    def update_item(params)
      select(params).map do |item_hash|
        item = internal_detect(params)
        next unless item

        case params[:event]
        when :add_network
          item.add_network_unless_exists(params[:network_id], params[:cookie_id])
        when :remove_network
          item.remove_network_if_exists(params[:network_id])
        when :remove_all_networks
          item.remove_all_networks
        end
      end
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

    def item_initialize(item_map, params)
      item = @items[item_map.id]
      return item if item

      mode = item_map.type.to_sym
      params = { dp_info: @dp_info,
                 manager: self,
                 id: item_map.id,
                 uuid: item_map.uuid,
                 type: item_map.type,
                 interface_id: item_map.interface_id }

      case mode
      when :dhcp       then Vnet::Openflow::Services::Dhcp.new(params)
      when :dns        then Vnet::Openflow::Services::Dns.new(params)
      when :router     then Vnet::Openflow::Services::Router.new(params)
      else
        nil
      end
    end

    def initialized_item_event
      INITIALIZED_SERVICE
    end

    def select_item(filter)
      MW::NetworkService[filter]
    end

    #
    # Event handlers:
    #

    def create_item(params)
      item_map = params[:item_map]
      item = @items[item_map.id]
      return unless item

      # if service_map.vif.mode == 'simulated'

      # if interface.active_datapath_id &&
      #     interface.active_datapath_id != @datapath.datapath_id
      #   return
      # end
      debug log_format("create #{item_map.uuid}/#{item_map.id}", "mode:#{item_map.type.to_sym}")

      item.install

      interface_item = @dp_info.interface_manager.item(id: item_map.interface_id)
      return item if interface_item.nil?

      interface_item.mac_addresses.map { |_, mac_info|  mac_info[:ipv4_addresses] }.flatten(1).compact.each do |ip_info|
        item.add_network_unless_exists(ip_info[:network_id], ip_info[:cookie_id])
      end

      if item.type == "dns"
        if dns_service_map = MW::DnsService.batch.find(network_service_id: item.id).commit(fill: :dns_records)
          publish(ADDED_DNS_SERVICE, id: item.id, dns_service_map: dns_service_map)
        end
      end

      item
    end    

    def delete_item(item)
      item = @items.delete(item.id)
      return unless item

      debug log_format("delete #{item.uuid}/#{item.id}", "mode:#{item.class.name.split("::").last.downcase}")

      item.uninstall

      item
    end

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

    def match_item?(item, params)
      return false if params[:interface_id] && params[:interface_id] != item.interface_id
      super
    end
  end

end
