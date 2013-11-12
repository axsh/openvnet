# -*- coding: utf-8 -*-

module Vnet::Openflow

  class ServiceManager < Manager

    #
    # Events:
    #
    subscribe_event :added_service # TODO Check if needed.
    subscribe_event :removed_service # TODO Check if needed.
    subscribe_event INITIALIZED_SERVICE, :create_item

    def update_item(params)
      select(params).map do |item_hash|
        item = internal_detect(params)
        next unless item

        case params[:event]
        when :add_network
          item.add_network_unless_exists(params[:network_id])
        when :remove_network
          item.remove_network_if_exists(params[:network_id])
        when :remove_all_networks
          item.remove_all_networks
        end
      end
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} service_manager: #{message}" + (values ? " (#{values})" : '')
    end

    def item_initialize(item_map)
      item = @items[item_map.id]
      return item if item

      mode = item_map.display_name.to_sym
      params = { dp_info: @dp_info,
                 manager: self,
                 id: item_map.id,
                 uuid: item_map.uuid,
                 interface_id: item_map.interface_id }

      case mode
      when :dhcp       then Vnet::Openflow::Services::Dhcp.new(params)
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
      debug log_format("insert #{item_map.uuid}/#{item_map.id}", "mode:#{item_map.display_name.to_sym}")

      item.install

      @dp_info.interface_manager.async.update_item(event: :add_service,
                                                   id: item_map.interface_id,
                                                   service: item_map.display_name.to_sym)

      item
    end    

    def match_item?(item, params)
      return false if params[:interface_id] && params[:interface_id] != item.interface_id
      super
    end
  end

end
