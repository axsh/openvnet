# -*- coding: utf-8 -*-

module Vnet::Openflow

  class DatapathManager < Manager

    #
    # Events:
    #
    subscribe_event :added_service # TODO Check if needed.
    subscribe_event :removed_service # TODO Check if needed.
    subscribe_event INITIALIZED_DATAPATH, :create_item

    def update(params)
      case params[:event]
      when :activate_route_link
        activate_route_link(params)
      when :activate_network
        activate_network(params)
      when :deactivate_route_link
        # deactivate_route_link(params)
      end

      nil
    end

    #
    # Networks:
    #

    def update_network(params)
      if @datapath_info.nil?
        error log_format('datapath information not loaded')
        return nil
      end

      return nil if params[:network_id].nil?

      case params[:event]
      when :activate then activate_network(params)
      when :deactivate then deactivate_network(params)
      end

      nil
    end

    #
    # Events:
    #

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} datapath_manager: #{message}" + (values ? " (#{values})" : '')
    end

    #
    # Specialize Manager:
    #

    def match_item?(item, params)
      return false if params[:id] && params[:id] != item.id
      return false if params[:uuid] && params[:uuid] != item.uuid
      true
    end
    
    def select_item(filter)
      # Using fill for ip_leases/ip_addresses isn't going to give us a
      # proper event barrier.
      MW::Datapath.batch[filter].commit(:fill => :host_interfaces)
    end

    def item_initialize(item_map)
      if item_map.dpid == @dp_info.dpid_s
        Datapaths::Host.new(dp_info: @dp_info,
                            manager: self,
                            map: item_map)
      else
        Datapaths::Remote.new(dp_info: @dp_info,
                              manager: self,
                              map: item_map)
      end
    end

    def initialized_item_event
      INITIALIZED_DATAPATH
    end

    def create_item(params)
      item = @items[params[:item_map].id]
      return unless item

      item.install

      debug log_format("insert #{item.uuid}/#{item.id}")

      item
    end

    def delete_item(item)
      @items.delete(item.id)

      item.uninstall
      item
    end

    #
    # Events:
    #

    def activate_network(params)
      return if params[:network_id].nil?

      dpn_items = MW::DatapathNetwork.batch.dataset.where(network_id: params[:network_id]).all.commit

      dpn_items.each { |dpn|
        item = item_by_params(id: dpn.datapath_id)
        next if item.nil?

        item.add_active_network(dpn)
      }
    end

    def deactivate_network(params)
      unused_datapaths = @items.select { |id, item|
        next false if !item.remove_active_network_id(item.id)
        item.is_unused?
      }

      unused_datapaths.each { |id, item|
        delete_item(item)
      }
    end

    def activate_route_link(params)
      return if params[:route_link_id].nil?

      dp_rl_items = MW::DatapathRouteLink.batch.dataset.where(route_link_id: params[:route_link_id]).all.commit(:fill => :route_link)

      dp_rl_items.each { |dp_rl|
        item = item_by_params(id: dp_rl.datapath_id)
        next if item.nil?

        item.add_active_route_link(dp_rl)
      }
    end

  end

end
