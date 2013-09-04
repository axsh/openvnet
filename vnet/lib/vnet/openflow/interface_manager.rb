# -*- coding: utf-8 -*-

module Vnet::Openflow

  class InterfaceManager
    include Celluloid
    include Celluloid::Logger
    include FlowHelpers

    def initialize(dp)
      @datapath = dp
      @interfaces = {}

      @dpid = @datapath.dpid
      @dpid_s = "0x%016x" % @datapath.dpid
      
    end

    def interface(params)
      if_to_hash(if_by_params(params))
    end

    def update_active_datapaths(params)
      interface = if_by_params_direct(params)

      return if interface.nil?

      interface.active_datapath_ids = interface.active_datapath_ids.dup.push(@datapath_id).uniq!
      MW::Vif.batch[:id => interface.id].update(:active_datapath_id => params[:datapath_id]).commit
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "interface_manager: #{message} (dpid:#{@dpid_s}#{values ? ' ' : ''}#{values})"
    end

    def if_to_hash(interface)
      interface && interface.to_hash
    end

    def if_by_params(params)
      interface = if_by_params_direct(params)

      if interface || params[:dynamic_load] == false
        return interface
      end

      select = case
               when params[:id]   then {:id => params[:id]}
               when params[:uuid] then params[:uuid]
               else
                 raise("Missing interface id/uuid parameter.")
               end

      create_interface(MW::Vif[select])
    end

    def if_by_params_direct(params)
      case
      when params[:id] then return @interfaces[params[:id]]
      when params[:uuid]
        interface = @interfaces.detect { |id, interface| interface.uuid == params[:uuid] }
        return interface && interface[1]
      else
        raise("Missing interface id/uuid parameter.")
      end
    end

    def create_interface(interface_map)
      return nil if interface_map.nil?

      interface = @interfaces[interface_map.id]
      return interface if interface

      debug log_format('insert', "interface:#{interface_map.uuid}/#{interface_map.id}")

      interface = Interfaces::Base.new(datapath: @datapath,
                                       map: interface_map)

      @interfaces[interface_map.id] = interface

      load_addresses(interface, interface_map)

      interface
    end

    def load_addresses(interface, interface_map)
      return if interface_map.mac_addr.nil?

      mac_address = Trema::Mac.new(interface_map.mac_addr)
      interface.add_mac_address(mac_address)

      network_id = interface_map.network_id
      return if network_id.nil?

      network_info = @datapath.network_manager.network_by_id(network_id)

      ipv4_address = interface_map.ipv4_address
      return if ipv4_address.nil?

      interface.add_ipv4_address(mac_address: mac_address,
                                 network_id: network_id,
                                 network_type: network_info[:type],
                                 ipv4_address: IPAddr.new(ipv4_address, Socket::AF_INET))
    end

  end

end
