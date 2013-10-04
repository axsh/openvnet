# -*- coding: utf-8 -*-

module Vnet::Openflow

  class DatapathManager < Manager

    #
    # Networks:
    #

    def update_network(params)
      # item = item_by_params(params)

      # return nil if item.nil?
      return nil if params[:network_id].nil?

      case params[:event]
      when :active then active_network(params)
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

    def active_network(params)
      # dp_map = @dp_info.datapath.datapath_map

      # if dp_map.nil?
      #   error log_format('datapath information not found in database')
      #   return nil
      # end

      # dpn_items = dp_map.batch.datapath_networks_dataset.where(:network_id => params[:network_id]).commit
      # dpn_items = dp_map.batch.dataset.find_all_by_network_id(params[:network_id]).commit
      
      # dpn_items = dp_map.batch.datapath_networks_dataset.commit

      # info dpn_items.inspect

#       dpn_items = MW::Datapath.batch[:dpid => @dp_info.dpid_s].

# dataset.find_all_by_network_id(params[:network_id]).commit

      info "ASDFASDFSADF"

      dpn_items.each { |dpn|
        info "XXXXXXXXXXXXXXXXXX"
        # debug "FFFF: #{params[:network_id]} #{dpn.inspect}"
      }

    end

  end

end
