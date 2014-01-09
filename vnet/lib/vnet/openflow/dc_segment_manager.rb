# -*- coding: utf-8 -*-

module Vnet::Openflow

  class DcSegmentManager < Manager

    def initialize(dp_info)
      super
      @port_numbers = []
      @host_datapath_networks = {}
      @interfaces = []
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

    def create_all_tunnels
      debug log_format("creating mac2mac flows")

      if @datapath_info.nil?
        error log_format('datapath information not loaded')
        return nil
      end

      # Since we make all the tunnels up-front we need to assume the
      # host ports are already created for all datapaths.
      datapath_map = MW::Datapath.batch[@datapath_info.id].commit(:fill => :host_interfaces)

      if datapath_map.host_interfaces.empty?
        error log_format("could not find any host interface for this datapath, aborting mac2mac flow creation")
        return
      end

      flows = []

      # We currently depend on the dc segment id despite this being
      # the wrong way to decide between tunnel and mac2mac.
      MW::Datapath.batch.on_same_segment(@datapath_info.id).all.commit(:fill => :host_interfaces).map { |target_dp_map|
        datapath_map.host_interfaces.map { |host_interface|
          target_dp_map.host_interfaces.map { |dst_interface|
            info log_format("creating mac2mac entry",
                            "src_host:#{host_interface.uuid}/#{host_interface.port_name} dst_host:#{dst_interface.uuid}/#{dst_interface.port_name}")

            prepare_interfaces(flows, target_dp_map.id, host_interface.id, dst_interface.id)
          }
        }
      }

      @dp_info.add_flows(flows)
    end

    def insert(dpn_id)
      dpn = create_datapath_network(dpn_id)
      return unless dpn

      info log_format("insert datapath network",
                      "network_id:#{dpn[:network_id]} dpn_id:#{dpn[:id]}")

      dpn_list = (@items[dpn[:network_id]] ||= {})

      if dpn_list.has_key? dpn[:id]
        warn log_format("datapath network id already exists",
                        "network_id:#{dpn[:network_id]} dpn_id:#{dpn[:id]}")
        return
      end

      dpn_list[dpn[:id]] = dpn

      options = {
        dst_datapath_id: dpn[:datapath_id],
        src_interface_id: @host_datapath_networks[dpn[:network_id]][:interface_id],
        dst_interface_id: dpn[:interface_id],
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

    def prepare_network(dpn_id)
      dpn = create_datapath_network(dpn_id)
      return unless dpn

      @host_datapath_networks[dpn[:network_id]] = dpn

      return unless dpn[:network_mode] == 'virtual'

      self.update_network_id(dpn[:network_id])
    end

    def prepare_interfaces(flows, datapath_id, src_interface_id, dst_interface_id)
      # TODO:
      #
      # MAC2MAC -> Do we need a relationship table, e.g. tunnel table
      # has a 'mode' entry?

      [true, false].each { |reflection|
        flows << flow_create(:default,
                             table: TABLE_OUTPUT_DP_OVER_MAC2MAC,
                             goto_table: TABLE_OUT_PORT_INTERFACE_EGRESS,
                             priority: 2,

                             match_value_pair_flag: reflection,
                             match_value_pair_first: src_interface_id,
                             match_value_pair_second: dst_interface_id,

                             clear_all: true,
                             write_interface: src_interface_id,
                             write_reflection: reflection,

                             cookie: datapath_id | COOKIE_TYPE_DATAPATH)
      }
    end

    def remove_network_id(network_id)
      @host_datapath_networks.delete(network_id)

      dpn_list = @items.delete(network_id)

      return if dpn_list.nil?

      debug log_format("remove network_id: #{network_id}")

      dpn_list.keys.each { |id|
        @dp_info.del_cookie(id | COOKIE_TYPE_DP_NETWORK)
      }

      update_network_id(network_id)
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
                         match_network: network_id,
                         actions: flood_actions,
                         cookie: network_id | COOKIE_TYPE_NETWORK,
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
    
    def create_datapath_network(dpn_id)
      dpn_map = MW::DatapathNetwork.batch[dpn_id].commit(fill: [ :datapath, :network ])
      return unless  dpn_map

      {
        id: dpn_map.id,
        broadcast_mac_address: Trema::Mac.new(dpn_map.broadcast_mac_address),
        datapath_id: dpn_map.datapath_id,
        network_id: dpn_map.network_id,
        network_mode: dpn_map.network.mode,
        interface_id: dpn_map.interface_id
      }
    end

    #
    # Specialize Manager:
    #

  end

end
