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

    def port_by_port_name(port_name)
      port_number, port = @ports.detect { |port_number, port|
        port_name == port.port_name
      }
      port_to_hash(port)
    end

    def insert(port_desc)
      debug log_format("insert port #{port_desc.name}",
                       "port_no:#{port_desc.port_no} hw_addr:#{port_desc.hw_addr} adv/supported:0x%x/0x%x" %
                       [port_desc.advertised, port_desc.supported])

      if @datapath.datapath_map.nil?
        warn log_format('cannot initialize ports without a valid datapath database entry')
        return nil
      end

      if @ports[port_desc.port_no]
        info log_format('port already initialized', "port_number:#{port_desc.port_no}")
        return port_to_hash(@ports[port_desc.port_no])
      end

      port = Ports::Base.new(@datapath, port_desc)
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
      debug log_format("remove port #{port_desc.name}",
                       "port_no:#{port_desc.port_no} hw_addr:#{port_desc.hw_addr} adv/supported:0x%x/0x%x" %
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
        @datapath.interface_manager.update_active_datapaths(uuid: port.port_name,
                                                            datapath_id: nil)
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
      port.ipv4_addr = @datapath.ipv4_address

      network = @datapath.network_manager.add_port(uuid: 'nw-public',
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

      network = @datapath.network_manager.add_port(uuid: 'nw-public',
                                                   port_number: port.port_number,
                                                   port_mode: :eth)

      if network
        port.network_id = network[:id]
      end

      port.install
    end

    def prepare_port_vif(port, port_desc)
      @datapath.mod_port(port.port_number, :no_flood)

      # TODO: Fix this so that when interface manager creates a new
      # interface, it checks if the port is present and get the
      # port number from port manager.
      interface = @datapath.interface_manager.item(uuid: port_desc.name,
                                                   port_number: port.port_number,
                                                   reinitialize: true)

      if interface.nil?
        error log_format("could not find uuid #{port_desc.name}")
        return
      end

      if interface.mode != :vif
        info log_format('vif mode not set to \'vif\'', "mode:#{interface.mode}")
        return
      end

      debug log_format("prepare_port_vif #{interface.uuid}")

      @datapath.interface_manager.update_active_datapaths(id: interface.id,
                                                          datapath_id: @datapath.datapath_map.id)

      port.extend(Ports::Vif)
      port.install
    end

    def prepare_port_tunnel(port, port_desc)
      @datapath.mod_port(port.port_number, :no_flood)

      port.extend(Ports::Tunnel)
      port.install
    end

  end

end
