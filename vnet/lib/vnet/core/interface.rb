# -*- coding: utf-8 -*-

require 'ostruct'

module Vnet::Core

  class Interface < OpenStruct
    include Vnet::Openflow::MetadataHelpers

    def get_ipv4_infos(params)
      case
      when params[:any_md]
        network_id = md_to_id(:network, params[:any_md])
        interface_id = md_to_id(:interface, params[:any_md])

        return [] if network_id.nil? && interface_id.nil?
        return [] if interface_id && interface_id != self.id

      when params[:network_md]
        network_id = md_to_id(:network, params[:network_md])
        return [] if network_id.nil?

      when params[:network_id]
        network_id = network_id
        return [] if network_id.nil?

      else
        network_id = params[:network_id]
      end

      ipv4_address = params[:ipv4_address]
      ipv4_address = ipv4_address != IPV4_BROADCAST ? ipv4_address : nil

      infos = []

      self.mac_addresses.each { |mac_lease_id, mac_info|
        mac_info[:ipv4_addresses].each { |ipv4_info|
          next if network_id && ipv4_info[:network_id] != network_id
          next if ipv4_address && ipv4_info[:ipv4_address] != ipv4_address

          infos << [mac_info, ipv4_info]
        }
      }

      infos
    end

  end

end
