# -*- coding: utf-8 -*-

module Vnet::Openflow

  class PortManager
    include Celluloid
    include Celluloid::Logger
    include FlowHelpers
    include Vnet::Event::Dispatchable

    def initialize(dp)
      @datapath = dp
      @ports = {}
    end

    #
    # Deprecated:
    #

    def eth_ports
      @ports.values.find_all { |port| port.eth? }
    end

    #
    #
    #

    def insert(port_desc)
      debug "port_manager.insert: #{port_desc.inspect}"

      if @datapath.datapath_map.nil?
        warn "port_manager.insert: cannot initialize ports without a valid datapath database entry (0x%016x)" % @datapath.dpid
        return
      end

      port = Ports::Base.new(@datapath, port_desc, true)
      @ports[port_desc.port_no] = port

      if port.port_number == OFPP_LOCAL
        @datapath.mod_port(port.port_number, :no_flood)

        port.extend(Ports::Local)
        port.hw_addr = port_desc.hw_addr
        port.ipv4_addr = @datapath.ipv4_address

        network = @datapath.network_manager.network_by_uuid('nw-public')

      elsif port.port_info.name =~ /^eth/
        @datapath.mod_port(port.port_number, :flood)

        eth_map = Vnet::ModelWrappers::Interface.find({:name => port.port_info.name})
        port.extend(Ports::Host)

        network = @datapath.network_manager.network_by_uuid('nw-public')

      elsif port.port_info.name =~ /^if-/
        @datapath.mod_port(port.port_number, :no_flood)

        interface_map = Vnet::ModelWrappers::Interface[port_desc.name]

        if interface_map.nil?
          error "error: Could not find uuid: #{port_desc.name}"
          return
        end

        network = @datapath.network_manager.network_by_uuid(interface_map.batch.network.commit.uuid)

        if network.class == NetworkPhysical
          port.extend(Ports::Physical)
        elsif network.class == NetworkVirtual
          port.extend(Ports::Virtual)
        else
          raise("Unknown network type.")
        end

        port.hw_addr = Trema::Mac.new(interface_map.batch.mac_addr.commit)
        port.ipv4_addr = IPAddr.new(interface_map.batch.ipv4_address.commit.first, Socket::AF_INET)

        interface_map.batch.update(:active_datapath_id => @datapath.datapath_map.id).commit

      elsif port.port_info.name =~ /^t-/
        @datapath.mod_port(port.port_number, :no_flood)

        port.extend(Ports::Tunnel)
      else
        @datapath.mod_port(port.port_number, :no_flood)

        error "Unknown interface type: #{port.port_info.name}"
        return
      end

      network.add_port(port, true) if network
      port.install
    end

    def remove(message)
      port = @ports.delete(message.port_no)

      if port.nil?
        debug "port status could not delete uninitialized port: #{message.port_no}"
        return
      end

      port.uninstall

      if port.network
        network = port.network
        network.del_port(port, true)

        if network.ports.empty?
          @datapath.network_manager.remove(network)
          @datapath.tunnel_manager.delete_tunnel_port(network.network_id, @datapath.dpid)
          dispatch_event("network/deleted", network_id: network.network_id, dpid: @datapath.dpid)
        end
      end

      if port.port_info.name =~ /^if-/
        if_map = MW::Interface[message.name]
        if_map.batch.update(:active_datapath_id => nil).commit
      end
    end

    def packet_in(message)
      port = @ports[message.match.in_port]

      @datapath.packet_manager.async.packet_in(port, message) if port
    end

  end

end
