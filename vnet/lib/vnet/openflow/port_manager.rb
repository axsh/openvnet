# -*- coding: utf-8 -*-

module Vnet::Openflow

  class PortManager < Manager

    def insert(port_desc)
      debug log_format("insert port #{port_desc.name}",
                       "port_no:#{port_desc.port_no} hw_addr:#{port_desc.hw_addr} adv/supported:0x%x/0x%x" %
                       [port_desc.advertised, port_desc.supported])

      if @dp_info.datapath.datapath_map.nil?
        warn log_format('cannot initialize ports without a valid datapath database entry')
        return nil
      end

      if @items[port_desc.port_no]
        info log_format('port already initialized', "port_number:#{port_desc.port_no}")
        return item_to_hash(@items[port_desc.port_no])
      end

      port = Ports::Base.new(@dp_info, port_desc)
      @items[port_desc.port_no] = port

      case
      when port.port_number == OFPP_LOCAL
        prepare_port_local(port, port_desc)
      when port.port_info.name =~ /^eth/
        prepare_port_eth(port, port_desc)
      when port.port_info.name =~ /^if-/
        prepare_port_vif(port, port_desc)
      when port.port_info.name =~ /^t-/
        prepare_port_tunnel(port, port_desc)
      else
        @dp_info.ovs_ofctl.mod_port(port.port_number, :no_flood)

        # Currently only support vif.
        interface = @dp_info.interface_manager.item(port_name: port_desc.name,
                                                    port_number: port.port_number)

        if interface
          prepare_port_vif(port, port_desc, interface)
        else
          error log_format('unknown interface type', "name:#{port.port_name}")
        end
      end

      item_to_hash(port)
    end

    def remove(port_desc)
      debug log_format("remove port #{port_desc.name}",
                       "port_no:#{port_desc.port_no} hw_addr:#{port_desc.hw_addr} adv/supported:0x%x/0x%x" %
                       [port_desc.advertised, port_desc.supported])

      port = @items.delete(port_desc.port_no)

      if port.nil?
        debug log_format('port status could not delete uninitialized port',
                         "port_number:#{port_desc.port_no}")
        return nil
      end

      port.uninstall

      @dp_info.interface_manager.update_item(event: :clear_port_number,
                                             port_number: port.port_number,
                                             dynamic_load: false)

      nil
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dp_info.dpid_s} port_manager: #{message}" + (values ? " (#{values})" : '')
    end

    #
    # Specialize Manager:
    #

    def match_item?(item, params)
      return false if params[:id] && params[:id] != item.id
      return false if params[:port_name] && params[:port_name] != item.port_name
      return false if params[:port_number] && params[:port_number] != item.port_number
      return false if params[:port_type] && params[:port_type] != item.port_type
      true
    end

    #
    # Ports:
    #

    def prepare_port_local(port, port_desc)
      @dp_info.ovs_ofctl.mod_port(port.port_number, :no_flood)

      port.extend(Ports::Local)
      port.ipv4_addr = @dp_info.datapath.ipv4_address

      port.install
    end

    def prepare_port_eth(port, port_desc)
      @dp_info.ovs_ofctl.mod_port(port.port_number, :flood)

      params = {
        :owner_datapath_id => @dp_info.datapath.datapath_map.id,
        :display_name => port_desc.name,
        :reinitialize => true
      }

      interface = @dp_info.interface_manager.item(params)

      if interface.nil?
        port.extend(Ports::Host)
      else
        port.extend(Ports::Generic)
        @dp_info.translation_manager.async.add_edge_port(port: port, interface: interface)
      end

      port.install
    end

    def prepare_port_vif(port, port_desc, interface = nil)
      # TODO: Fix this so that when interface manager creates a new
      # interface, it checks if the port is present and get the
      # port number from port manager.
      if interface.nil?
        @dp_info.ovs_ofctl.mod_port(port.port_number, :no_flood)

        interface = @dp_info.interface_manager.item(uuid: port_desc.name,
                                                    port_number: port.port_number)
      end

      if interface.nil?
        error log_format("could not find interface for #{port_desc.name}")
        return
      end

      if interface.mode != :vif
        info log_format('interface mode not set to \'vif\' for #{interface.uuid}', "mode:#{interface.mode}")
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

    def prepare_port_tunnel(port, port_desc)
      @dp_info.ovs_ofctl.mod_port(port.port_number, :no_flood)

      tunnel = @dp_info.tunnel_manager.item(port_name: port.port_name)

      if tunnel.nil?
        error log_format("could not find tunnel for #{port.port_name}")
        return
      end

      port.extend(Ports::Tunnel)

      port.dst_id = tunnel.dst_id
      port.install
    end

  end

end
