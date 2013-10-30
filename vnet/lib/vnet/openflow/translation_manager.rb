# -*- coding: utf-8 -*-

module Vnet::Openflow
  class TranslationManager < Manager
    include Celluloid::Logger
    include FlowHelpers
    include Vnet::Event::Dispatchable

    def initialize(dp_info)
      @dp_info = dp_info
      @dpid_s = "0x%016x" % @dp_info.dpid
      @edge_ports = []

      add_handler(mode: :vnet_edge, dp_info: @dp_info)
      update_translation_map
    end

    def add_edge_port(params)
      @edge_ports << {
        :port => params[:port],
        :interface => params[:interface],
        :vlan_vs_mac_address => []
      }
    end

    def network_to_vlan(network_id)
      entry = @translation_map.find { |t| t.network_id == network_id }
      return nil if entry.nil?
      entry.vlan_id
    end

    def vlan_to_network(vlan_vid)
      entry = @translation_map.find { |t| t.vlan_id == vlan_vid }
      entry.network_id
    end

    #
    # Internal methods:
    #

    private
    
    def translation_hander_initialize(mode, params)
      case mode
      when :vnet_edge  then Translations::VnetEdgeHandler.new(params)
      else
        error log_format('failed to create translation handler', "name: #{mode}")
        nil
      end
    end

    def add_handler(mode, params)
      item = translation_handler_initialize(mode, params)

      return nil if item.nil?

      @items[item.id] = item
    end

    def log_format(message, values = nil)
      "#{@dpid_s} translation_manager: #{message}" + (values ? " (#{values})" : '')
    end

    #
    # Specialize Manager:
    #

    def select_filter_from_params(params)
      case
      when params[:id]   then {:id => params[:id]}
      when params[:uuid] then params[:uuid]
      when params[:display_name] && params[:owner_datapath_id]
        { :display_name => params[:display_name],
          :owner_datapath_id => params[:owner_datapath_id]
        }
      else
        # Any invalid params that should cause an exception needs to
        # be caught by the item_by_params_direct method.
        return nil
      end
    end

    def update_translation_map
      @translation_map = Vnet::ModelWrappers::VlanTranslation.batch.all.commit
    end

  end

end
