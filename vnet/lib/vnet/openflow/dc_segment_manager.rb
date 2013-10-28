# -*- coding: utf-8 -*-

module Vnet::Openflow

  class DcSegmentManager < Manager

    def initialize(dp_info)
      @port_numbers = []
      super
    end

    #
    # Events:
    #

    def update(params)
      case params[:event]
      when :insert_port_number
        return nil if params[:port_number].nil?
        return nil if @port_numbers.find_index(params[:port_number])

        @port_numbers << params[:port_number]

        update_all

      when :remove_port_number
        return nil if params[:port_number].nil?

        port_number = @port_numbers.delete(params[:port_number])
        return nil if port_number.nil?

        update_all
      end

      nil
    end

    #
    # Refactor...
    #

    def insert(dpn_map)
      info log_format("insert datapath network id #{dpn_map.id}",
                      "network.id:#{dpn_map.network_id}")

      dpn_list = (@items[dpn_map.network_id] ||= {})

      if dpn_list.has_key? dpn_map.id
        warn log_format("datapath network id already exists",
                        "network_id:#{dpn_map.network_id}) dpn_id:#{dpn_map.id}")
        return
      end

      dpn = {
        :id => dpn_map.id,
        :broadcast_mac_address => Trema::Mac.new(dpn_map.broadcast_mac_address),
      }

      dpn_list[dpn_map.id] = dpn

      self.update_network_id(dpn_map.network_id)
    end

    #
    # Update state:
    #

    def update_all
      @items.each { |id, item|
        update_network_id(id)
      }
    end

    def prepare_network(network_map, datapath_info)
      return unless network_map.network_mode == 'virtual'

      network_map.batch.datapath_networks_dataset.on_segment(@datapath_info).all.commit(:fill => :datapath).each { |dpn_map|
        self.insert(dpn_map)
      }

      dpn = MW::DatapathNetwork[datapath_id: datapath_info.id,
                                network_id: network_map.id]

      flow = flow_create(:host_ports,
                         priority: 30,
                         match: { :eth_dst => Trema::Mac.new(dpn.broadcast_mac_address) },
                         actions: { :eth_dst => MAC_BROADCAST },
                         write_metadata: { :network => network_map.id },
                         cookie: network_map.id | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT),
                         goto_table: TABLE_NETWORK_SRC_CLASSIFIER)

      @dp_info.add_flow(flow)

      self.update_network_id(network_map.id)
    end

    def remove_network_id(network_id)
      dpn_list = @items.delete(network_id)

      return if dpn_list.nil?

      dpn_list.each { |dpn|
        @dp_info.del_cookie(dpn[:id] | (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT))
      }
    end

    def update_network_id(network_id)
      dpn_list = @items[network_id]

      if @port_numbers.empty? || dpn_list.nil?
        flood_actions = []
      else
        flood_actions = dpn_list.collect { |dpn_id,dpn|
          { :eth_dst => dpn[:broadcast_mac_address],
            :output => @port_numbers.first
          }
        }
        flood_actions << {:eth_dst => MAC_BROADCAST} unless flood_actions.empty?
      end

      flow = flow_create(:default,
                         table: TABLE_FLOOD_SEGMENT,
                         priority: 1,
                         match_metadata: { :network => network_id },
                         actions: flood_actions,
                         cookie: network_id | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT),
                         goto_table: TABLE_FLOOD_TUNNELS)

      @dp_info.add_flow(flow)
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} dc_segment_manager: #{message}" + (values ? " (#{values})" : '')
    end
    
    #
    # Specialize Manager:
    #

  end

end
