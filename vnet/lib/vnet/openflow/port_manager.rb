# -*- coding: utf-8 -*-

module Vnet::Openflow

  class PortManager < Manager

    #
    # Events:
    #
    subscribe_event INITIALIZED_PORT, :install_item
    subscribe_event FINALIZED_PORT, :uninstall_item

    def insert(port_desc)
      debug log_format("insert port #{port_desc.name}",
                       "port_no:#{port_desc.port_no} hw_addr:#{port_desc.hw_addr} adv/supported:0x%x/0x%x" %
                       [port_desc.advertised, port_desc.supported])

      if @dp_info.datapath.datapath_info.nil?
        warn log_format('cannot initialize ports without a valid datapath database entry')
        return nil
      end

      if @items[port_desc.port_no]
        info log_format('port already initialized', "port_number:#{port_desc.port_no}")
        return item_to_hash(@items[port_desc.port_no])
      end

      port = Ports::Base.new(@dp_info, port_desc)
      @items[port.port_number] = port

      publish(INITIALIZED_PORT, id: port.id)
    end

    def remove(port_desc)
      debug log_format("remove port #{port_desc.name}",
                       "port_no:#{port_desc.port_no} hw_addr:#{port_desc.hw_addr} adv/supported:0x%x/0x%x" %
                       [port_desc.advertised, port_desc.supported])

      port = @items[port_desc.port_no]
      if port.nil?
        debug log_format('port status could not delete uninitialized port',
                         "port_number:#{port_desc.port_no}")
        return nil
      end

      publish(FINALIZED_PORT, id: port.id)

      item_to_hash(port)
    end

    def attach_interface(params)
      port = internal_detect(params)
      return unless port

      # reinitialize
      if port.installed?
        publish(FINALIZED_PORT, id: port.id)
      end

      publish(INITIALIZED_PORT, id: port.id)
    end

    def detach_interface(params)
      # currently attach_interface and detach_interface is tha same thing.
      attach_interface(params)
    end

    #
    # Internal methods:
    #

    private

    #
    # Event handlers.
    #

    def install_item(params)
      port = @items[params[:id]]
      return unless port
      return if port.installed?

      if port.port_number == OFPP_LOCAL
        prepare_port_local(port)
        return item_to_hash(port)
      end

      interface = @dp_info.interface_manager.item(port_name: port.port_name,
                                                  port_number: port.port_number,
                                                  owner_datapath_id: @dp_info.datapath.datapath_info.id)

      # Request twice since we're lacking the proper search parameter.
      interface = interface || @dp_info.interface_manager.item(port_name: port.port_name,
                                                               port_number: port.port_number,
                                                               owner_datapath_id: nil)

      if interface
        case interface.mode
        when :host, :edge
          prepare_port_eth(port, interface)
        when :vif
          prepare_port_vif(port, interface)
        else
          @dp_info.ovs_ofctl.mod_port(port.port_number, :no_flood)

          error log_format('unknown interface mode', "name:#{port.port_name} type:#{interface.mode}")
        end
      else
        case
        when port.port_info.name =~ /^t-/
          prepare_port_tunnel(port)
        else
          @dp_info.ovs_ofctl.mod_port(port.port_number, :no_flood)

          error log_format('unknown interface type', "name:#{port.port_name}")
        end
      end

      item_to_hash(port)
    end

    def uninstall_item(params)
      port = @items[params[:id]]
      return unless port && port.installed?

      @items.delete(params[:id])

      # reinitialize port
      @items[port.port_number] = Ports::Base.new(@dp_info, port.port_info)

      port.uninstall

      debug log_format("uninstall #{port.port_name}/#{port.id}")

      interface = @dp_info.interface_manager.item(
        port_number: port.port_number,
        dynamic_load: false
      )

      if interface
        @dp_info.interface_manager.update_item(
          event: :clear_port_number,
          id: interface.id
        )
      end

      nil
    end

    #
    # Specialize Manager:
    #

    def match_item?(item, params)
      return true if params[:port_name] && params[:port_name] == item.port_name
      return true if params[:port_number] && params[:port_number] == item.port_number
      return true if params[:port_type] && params[:port_type] == item.port_type
      false
    end

    #
    # Ports:
    #

    def prepare_port_local(port)
      @dp_info.ovs_ofctl.mod_port(port.port_number, :no_flood)

      port.extend(Ports::Local)
      port.install
    end

    def prepare_port_eth(port, interface)
      @dp_info.ovs_ofctl.mod_port(port.port_number, :flood)

      if interface.nil?
        error log_format("could not find interface for #{port.port_name}")
        return
      end

      params = {
        :owner_datapath_id => @dp_info.datapath.datapath_info.id,
        :port_name => port.port_name,
        :reinitialize => true
      }

      if interface.mode == :host
        port.extend(Ports::Host)
        port.interface_id = interface.id

        # We don't need to query the interface before updating it, so do
        # this directly instead of the item request.
        interface = @dp_info.interface_manager.update_item(event: :set_port_number,
                                                           id: interface.id,
                                                           port_number: port.port_number)
      elsif interface.mode == :edge
        port.extend(Ports::Generic)
        port.interface_id = interface.id

      else
        error log_format("unknown port type", interface.mode)
      end

      port.install
    end

    def prepare_port_vif(port, interface)
      @dp_info.ovs_ofctl.mod_port(port.port_number, :no_flood)

      if interface.nil?
        error log_format("could not find interface for #{port.port_name}")
        return
      end

      debug log_format("prepare_port_vif #{interface.uuid}", "port_name:#{port.port_name}")

      port.extend(Ports::Vif)

      port.interface_id = interface.id
      port.install

      # We don't need to query the interface before updating it, so do
      # this directly instead of the item request.
      interface = @dp_info.interface_manager.update_item(event: :set_port_number,
                                                         id: interface.id,
                                                         port_number: port.port_number)
    end

    def prepare_port_tunnel(port)
      @dp_info.ovs_ofctl.mod_port(port.port_number, :no_flood)

      tunnel = @dp_info.tunnel_manager.item(uuid: port.port_name)

      if tunnel.nil?
        error log_format("could not find tunnel for #{port.port_name}")
        return
      end

      @dp_info.tunnel_manager.update_item(
        event: :set_port_number,
        id: tunnel.id,
        port_number: port.port_number
      )

      port.extend(Ports::Tunnel)

      port.dst_datapath_id = tunnel.dst_datapath_id
      port.tunnel_id = tunnel.id

      port.install
    end

  end

end
