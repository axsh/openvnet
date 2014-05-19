# -*- coding: utf-8 -*-

module Vnet::Openflow

  class PortManager < Vnet::Openflow::Manager

    #
    # Events:
    #
    subscribe_event PORT_INITIALIZED, :install_item
    subscribe_event PORT_FINALIZED, :uninstall_item

    subscribe_event PORT_ATTACH_INTERFACE, :attach_interface
    subscribe_event PORT_DETACH_INTERFACE, :detach_interface

    def initialize_ports
      return if @datapath_info.nil?

      @items.each { |id, item|
        publish(PORT_INITIALIZED, id: item.id)
      }
    end

    def insert(port_desc)
      if @items[port_desc.port_no]
        info log_format('port already added', "port_name:#{port_desc.name} port_number:#{port_desc.port_no}")
        return
      end

      port = Ports::Base.new(dp_info: @dp_info,
                             id: port_desc.port_no,
                             port_desc: port_desc)
      @items[port.port_number] = port

      debug log_format("insert port #{port_desc.name}",
                       "port_no:#{port_desc.port_no} hw_addr:#{port_desc.hw_addr} adv/supported:0x%x/0x%x" %
                       [port_desc.advertised, port_desc.supported])

      # The default setting is no_flood in order to ensure ovs does
      # not attempt to send any arp requests to the port during
      # initialization.
      @dp_info.ovs_ofctl.mod_port(port.port_number, :no_flood)

      # TODO: Allow limited initialization of e.g. LOCAL and host ports.
      if @datapath_info.nil?
        warn log_format('datapath_info not yet set, postponing initialization')
        return
      end

      publish(PORT_INITIALIZED, id: port.id)
    end

    def remove(port_desc)
      debug log_format("remove port #{port_desc.name}",
                       "port_no:#{port_desc.port_no} hw_addr:#{port_desc.hw_addr} adv/supported:0x%x/0x%x" %
                       [port_desc.advertised, port_desc.supported])

      port = @items[port_desc.port_no]

      if port.nil?
        debug log_format('port status could not delete uninitialized port',
                         "port_number:#{port_desc.port_no}")
        return
      end

      publish(PORT_FINALIZED, id: port.id)
    end

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def match_item_proc_part(filter_part)
      filter, value = filter_part

      case filter
      when :id, :port_name, :port_number, :port_type
        proc { |id, item| value == item.send(filter) }
      else
        raise NotImplementedError, filter
      end
    end

    #
    # Event handlers.
    #

    def install_item(params)
      port = @items[params[:id]] || return
      return if port.installed?

      case
      when port.port_number == OFPP_LOCAL
        prepare_port_local(port)
      when port.port_desc.name =~ /^t-/
        prepare_port_tunnel(port)
      else
        # TODO: Set flood off.

        @dp_info.interface_manager.publish(INTERFACE_ACTIVATE_PORT,
                                           id: :port,
                                           port_name: port.port_name,
                                           port_number: port.port_number)
      end
    end

    def uninstall_item(params)
      port = @items.delete(params[:id]) || return

      port.try_uninstall

      # We always trigger the deactivate event even if interface_id is
      # not set, as there might otherwise be a race-condition with
      # activation events.
      @dp_info.interface_manager.publish(INTERFACE_DEACTIVATE_PORT,
                                         id: :port,
                                         interface_id: port.interface_id,
                                         port_name: port.port_name,
                                         port_number: port.port_number)

      debug log_format("uninstall #{port.port_name}/#{port.id}")
    end

    # TODO: Make sure to verify we don't have duplicate port names, don't trust OVS.

    def attach_interface(params)
      port = @items[params[:id]] || return
      return if port.installed?

      interface = params[:interface] || return      

      case interface.mode
      when :host, :edge, :patch
        prepare_port_eth(port, interface)
      when :vif
        prepare_port_vif(port, interface)
      else
        error log_format('unknown interface mode', "name:#{port.port_name} type:#{interface.mode}")
      end
    end

    def detach_interface(params)
      item = @items[params[:id]] || return
      return unless item.installed?

      @items[item.id] = Ports::Base.new(dp_info: @dp_info,
                                        id: item.id,
                                        port_desc: item.port_desc)

      item.try_uninstall

      debug log_format("uninstall #{item.port_name}/#{item.id}")
    end

    #
    # Ports:
    #

    def prepare_port_local(port)
      port.extend(Ports::Local)
      port.try_install
    end

    def prepare_port_eth(port, interface)
      @dp_info.ovs_ofctl.mod_port(port.port_number, :flood)

      if interface.nil?
        error log_format("could not find interface for #{port.port_name}")
        return
      end

      if interface.mode == :host || interface.mode == :patch
        port.extend(Ports::Host)
        port.interface_id = interface.id

      elsif interface.mode == :edge
        port.extend(Ports::Generic)
        port.interface_id = interface.id

      else
        error log_format("unknown port type", interface.mode)
      end

      port.try_install
    end

    def prepare_port_vif(port, interface)
      debug log_format("prepare_port_vif #{interface.uuid}", "port_name:#{port.port_name}")

      port.extend(Ports::Vif)

      port.interface_id = interface.id
      port.try_install
    end

    def prepare_port_tunnel(port)
      debug log_format("prepare_port_tunnel", "port_name:#{port.port_name}")

      tunnel = @dp_info.tunnel_manager.retrieve(uuid: port.port_name)

      if tunnel.nil?
        error log_format("could not find tunnel for #{port.port_name}")
        return
      end

      port.extend(Ports::Tunnel)

      port.dst_datapath_id = tunnel.dst_datapath_id
      port.tunnel_id = tunnel.id

      port.try_install
    end

  end

end
