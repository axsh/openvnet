# -*- coding: utf-8 -*-

module Vnet::Openflow

  class PortManager
    include Celluloid
    include Celluloid::Logger
    include FlowHelpers

    def initialize(dp)
      @datapath = dp
      @ports = {}

      @dpid = @datapath.dpid
      @dpid_s = "0x%016x" % @datapath.dpid
    end

    def ports(params = {})
      @ports.select { |key, port|
        result = true
        result = result && (port.port_type == params[:port_type]) if params[:port_type]
      }.map { |key, port|
        port_to_hash(port)
      }
    end

    def port_by_port_number(port_number)
      port_to_hash(@ports[port_number])
    end

    def insert(port_desc)
      debug log_format('insert port',
                       "port_no:#{port_desc.port_no} name:#{port_desc.name} " +
                       "hw_addr:#{port_desc.hw_addr} adv/supported:0x%x/0x%x" %
                       [port_desc.advertised, port_desc.supported])

      if @datapath.datapath_map.nil?
        warn log_format('cannot initialize ports without a valid datapath database entry')
        return nil
      end

      if @ports[port_desc.port_no]
        info log_format('port already initialized', "port_number:#{port_desc.port_no}")
        return port_to_hash(@ports[port_desc.port_no])
      end

      port = Ports::Base.new(@datapath, port_desc, true)
      @ports[port_desc.port_no] = port

      case
      when port.port_number == OFPP_LOCAL
        prepare_port_local(port, port_desc)
      when port.port_info.name =~ /^eth/
        prepare_port_eth(port, port_desc)
      when port.port_info.name =~ /^vif-/
        prepare_port_vif(port, port_desc)
      when port.port_info.name =~ /^t-/
        prepare_port_tunnel(port, port_desc)
      else
        @datapath.mod_port(port.port_number, :no_flood)

        error log_format('unknown interface type', 'name:#{port.port_info.name}')
      end

      port_to_hash(port)
    end

    def remove(port_desc)
      debug log_format('remove port',
                       "port_no:#{port_desc.port_no} name:#{port_desc.name} " +
                       "hw_addr:#{port_desc.hw_addr} adv/supported:0x%x/0x%x" %
                       [port_desc.advertised, port_desc.supported])

      port = @ports.delete(port_desc.port_no)

      if port.nil?
        debug log_format('port status could not delete uninitialized port',
                         "port_number:#{port_desc.port_no}")
        return nil
      end

      port.uninstall

      if port.network_id
        @datapath.network_manager.del_port_number(port.network_id, port.port_number)
      end

      if port.port_name =~ /^vif-/
        vif_map = MW::Vif[port_desc.name]
        vif_map.batch.update(:active_datapath_id => nil).commit
      end

      nil
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dpid_s} port_manager: #{message}" + (values ? " (#{values})" : '')
    end

    def port_to_hash(port)
      port && port.to_hash
    end

    #
    # Ports:
    #

    def prepare_port_local(port, port_desc)
      @datapath.mod_port(port.port_number, :no_flood)

      port.extend(Ports::Local)
      port.hw_addr = port_desc.hw_addr
      port.ipv4_addr = @datapath.ipv4_address

      network = @datapath.network_manager.add_port(network_uuid: 'nw-public',
                                                   port_number: port.port_number,
                                                   port_mode: :local)
      if network
        port.network_id = network[:id]
      end

      port.install
    end

    def prepare_port_eth(port, port_desc)
      @datapath.mod_port(port.port_number, :flood)

      port.extend(Ports::Host)

      network = @datapath.network_manager.add_port(network_uuid: 'nw-public',
                                                   port_number: port.port_number,
                                                   port_mode: :eth)
      if network
        port.network_id = network[:id]
      end

      port.install
    end

    def prepare_port_vif(port, port_desc)
      @datapath.mod_port(port.port_number, :no_flood)

      interface = @datapath.interface_manager.item(uuid: port_desc.name)

      vif_map = MW::Vif[port_desc.name]
      return nil if vif_map.nil?

      if interface.nil?
        error log_format('could not find uuid', "name:#{port_desc.name})")
        return
      end

      if interface.mode != :vif
        info log_format('vif mode not set to \'vif\'', "mode:#{interface.mode}")
        return
      end

      debug "prepare_port_vif: #{vif_map.uuid}, hw_addr: #{vif_map.mac_address}"
      port.hw_addr = Trema::Mac.new(vif_map.mac_address)
      port.ipv4_addr = IPAddr.new(vif_map.ipv4_address, Socket::AF_INET) if vif_map.ipv4_address

      @datapath.interface_manager.update_active_datapaths(id: interface.id,
                                                          datapath_id: @datapath.datapath_map.id)

      network = @datapath.network_manager.add_port(network_id: vif_map.network_id,
                                                   port_number: port.port_number,
                                                   port_mode: :vif)

      if network
        case network[:type]
        when :physical then port.extend(Ports::Physical)
        when :virtual  then port.extend(Ports::Virtual)
        else
          raise("Unknown network type.")
        end

        port.network_id = network[:id]
      end

      port.install
    end

    def prepare_port_tunnel(port, port_desc)
      @datapath.mod_port(port.port_number, :no_flood)

      port.extend(Ports::Tunnel)
      port.install
    end

  end

end
