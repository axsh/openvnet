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

      interface
    end

  end

end
