# -*- coding: utf-8 -*-

module Vnet::Openflow::Datapaths

  class Base
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_accessor :id
    attr_accessor :uuid

    def initialize(params)
      @dp_info = params[:dp_info]
      @manager = params[:manager]

      map = params[:map]

      @id = map.id
      @uuid = map.uuid

      @active_networks = {}
    end
    
    # def cookie(tag = nil)
    #   value = @id | COOKIE_TYPE_INTERFACE
    #   tag.nil? ? value : (value | (tag << COOKIE_TAG_SHIFT))
    # end

    def to_hash
      { :id => @id,
        :uuid => @uuid,
      }
    end

    def is_unused?
      return false if !@active_networks.empty?
      true
    end

    def install
    end

    def uninstall
      debug log_format("removing flows")

      # cookie_value = self.cookie
      # cookie_mask = COOKIE_PREFIX_MASK | COOKIE_ID_MASK

      # @dp_info.del_cookie(cookie_value, cookie_mask)
    end

    #
    # Networks:
    #

    def add_active_network(dpn_map)
      debug log_format("adding to #{@uuid}/#{id} active datapath network #{dpn_map.datapath_id}/#{dpn_map.network_id}")

      return if @active_networks.has_key? dpn_map.id

      active_network = {
        :dpn_id => dpn_map.id,
        :datapath_id => dpn_map.datapath_id,
        :network_id => dpn_map.network_id,
        :broadcast_mac_address => Trema::Mac.new(dpn_map.broadcast_mac_address),
      }

      @active_networks[dpn_map.network_id] = active_network

      cookie = active_network[:dpn_id] | COOKIE_TYPE_DP_NETWORK

      flows = []
      flows << flow_create(:default,
                           table: TABLE_NETWORK_SRC_CLASSIFIER,
                           priority: 90,
                           match: {
                             :eth_src => active_network[:broadcast_mac_address]
                           },
                           cookie: cookie)
      flows << flow_create(:default,
                           table: TABLE_NETWORK_SRC_CLASSIFIER,
                           priority: 90,
                           match: {
                             :eth_dst => active_network[:broadcast_mac_address]
                           },
                           cookie: cookie)
      flows << flow_create(:default,
                           table: TABLE_NETWORK_DST_CLASSIFIER,
                           priority: 90,
                           match: {
                             :eth_src => active_network[:broadcast_mac_address]
                           },
                           cookie: cookie)
      flows << flow_create(:default,
                           table: TABLE_NETWORK_DST_CLASSIFIER,
                           priority: 90,
                           match: {
                             :eth_dst => active_network[:broadcast_mac_address]
                           },
                           cookie: cookie)

      @dp_info.add_flows(flows)
    end

    def remove_active_network_id(network_id)
      active_network = @active_networks.delete(network_id)
      return false if active_networks.nil?

      debug log_format("removing from #{@uuid}/#{id} active datapath network #{network_id}")

      @dp_info.del_cookie(active_network[:dpn_id] | COOKIE_TYPE_DP_NETWORK)
      
      true
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} datapaths/base: #{message}" + (values ? " (#{values})" : '')
    end

  end

end
