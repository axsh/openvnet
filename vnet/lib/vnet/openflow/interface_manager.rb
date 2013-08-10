# -*- coding: utf-8 -*-

module Vnet::Openflow

  class InterfaceManager < Manager

    def update_active_datapaths(params)
      interface = item_by_params_direct(params)
      return nil if interface.nil?

      interface.active_datapath_ids = interface.active_datapath_ids.dup.push(@datapath_id).uniq!
      MW::Vif.batch[:id => interface.id].update(:active_datapath_id => params[:datapath_id]).commit

      nil
    end

    def get_ipv4_address(params)
      interface = item_by_params_direct(params)
      return nil if interface.nil?

      interface.get_ipv4_address(params)
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dpid_s} interface_manager: #{message}" + (values ? " (#{values})" : '')
    end

    def interface_initialize(mode, params)
      case mode
      when :simulated then Interfaces::Simulated.new(params)
      else
        Interfaces::Base.new(params)
      end
    end

    def select_item(filter)
      MW::Vif[filter]
    end

    def create_item(item_map)
      return nil if item_map.nil?

      interface = @items[item_map.id]
      return interface if interface

      debug log_format('insert', "interface:#{item_map.uuid}/#{item_map.id}")

      interface = interface_initialize(item_map.mode.to_sym,
                                       datapath: @datapath,
                                       manager: self,
                                       map: item_map)

      @items[item_map.id] = interface

      interface.install

      load_addresses(interface, item_map)

      interface
    end

    def load_addresses(interface, item_map)
      return if item_map.mac_addr.nil?

      mac_address = Trema::Mac.new(item_map.mac_addr)
      interface.add_mac_address(mac_address)

      network_id = item_map.network_id
      return if network_id.nil?

      network_info = @datapath.network_manager.network_by_id(network_id)

      ipv4_address = item_map.ipv4_address
      return if ipv4_address.nil?

      interface.add_ipv4_address(mac_address: mac_address,
                                 network_id: network_id,
                                 network_type: network_info[:type],
                                 ipv4_address: IPAddr.new(ipv4_address, Socket::AF_INET))
    end

  end

end
