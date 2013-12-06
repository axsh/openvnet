# -*- coding: utf-8 -*-

module Vnet::Openflow

  module AddressHelpers

    def ipv4_address_find(params)
      network_id = params[:network_id]

      mac_info = @mac_addresses.values.detect { |mac_info|
        ipv4_info = mac_info[:ipv4_addresses].detect { |ipv4_info|
          next false if network_id && ipv4_info[:network_id] != network_id

          true
        }
      }

      mac_info && [mac_info, ipv4_info]
    end

    def add_mac_address(params)
      #debug log_format("add_ipv4_address", params.inspect)
      return if @mac_addresses[params[:mac_lease_id]]

      mac_addresses = @mac_addresses.dup
      mac_info = {
        ipv4_addresses: [],
        mac_address: params[:mac_address],
        cookie_id: params[:cookie_id],
      }

      mac_addresses[params[:mac_lease_id]] = mac_info

      @mac_addresses = mac_addresses

      debug log_format("adding mac address to #{@uuid}/#{@id}",
                       "#{params[:mac_address].to_s}")

      mac_info
    end

    def remove_mac_address(params)
      debug log_format("remove_mac_address", params.inspect)

      mac_info = @mac_addresses[params[:mac_lease_id]]
      return unless mac_info

      mac_info[:ipv4_addresses].each do |ipv4_info|
        remove_ipv4_address(ip_lease_id: ipv4_info[:ip_lease_id])
      end

      mac_addresses = @mac_addresses.dup
      mac_addresses.delete(params[:mac_lease_id])
      @mac_addresses = mac_addresses
    end

    def add_ipv4_address(params)
      #debug log_format("add_ipv4_address", params.inspect)

      mac_info = @mac_addresses[params[:mac_lease_id]]
      return unless mac_info

      # Check if the address already exists.

      ipv4_info = {
        :network_id => params[:network_id],
        :network_type => params[:network_type],
        :ipv4_address => params[:ipv4_address],
        :ip_lease_id => params[:ip_lease_id],
        :cookie_id => params[:cookie_id],
      }

      ipv4_addresses = mac_info[:ipv4_addresses].dup
      ipv4_addresses << ipv4_info

      mac_info[:ipv4_addresses] = ipv4_addresses

      debug log_format("adding ipv4 address to #{@uuid}/#{@id}",
                       "#{mac_info[:mac_address].to_s}/#{ipv4_info[:ipv4_address].to_s}")

      [mac_info, ipv4_info]
    end

    def remove_ipv4_address(params)
      # debug log_format("remove_ipv4_address", params.inspect)

      ipv4_info = nil
      ipv4_addresses = nil
      mac_info = @mac_addresses.values.find do |m|
        ipv4_info, ipv4_addresses = m[:ipv4_addresses].partition do |i|
          i[:ip_lease_id] == params[:ip_lease_id]
        end
        ipv4_info = ipv4_info.first
      end
      return unless mac_info

      mac_info[:ipv4_addresses] = ipv4_addresses

      debug log_format("removing ipv4 address from #{@uuid}/#{@id}",
                       "#{mac_info[:mac_address].to_s}/#{ipv4_info[:ipv4_address].to_s}")

      del_cookie_for_ip_lease(ipv4_info[:cookie_id])
      
      [mac_info, ipv4_info]
    end

    def ipv4_addresses
      @mac_addresses.values.map { |m| m[:ipv4_addresses] }.flatten(1)
    end

    def has_network?(network_id)
      ipv4_addresses.any?{ |i| i[:network_id] == network_id }
    end
  end

end
