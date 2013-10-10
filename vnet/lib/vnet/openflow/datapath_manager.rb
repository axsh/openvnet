# -*- coding: utf-8 -*-

module Vnet::Openflow

  class DatapathManager < Manager

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

    def handle_event(params)
      debug log_format("handle event #{params[:event]}", "#{params.inspect}")

      item = @items[:target_id]

      case params[:event]
      when :added
        return nil if item
        # Check if needed.
      when :removed
        return nil if item
        # Check if needed.
      end

      nil
    end
    
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
      MW::Datapath.batch[filter].commit #(:fill => [:ip_leases => :ip_address])
    end

    def create_item(item_map, params)
      item = Datapaths::Base.new(dp_info: @dp_info,
                                 manager: self,
                                 map: item_map)
      return nil if item.nil?

      @items[item_map.id] = item

      debug log_format("insert #{item_map.uuid}/#{item_map.id}")

      item.install
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

  end

end
