# -*- coding: utf-8 -*-

require 'ipaddr'
require 'trema'

module Vnet::Plugins
  class VdcVnetPlugin
    include Celluloid
    include Celluloid::Logger

    attr_reader :table

    def initialize
      @table = {
        :NetworkVif => :Interface,
        :NetworkVifIpLease => :IpLease,
      }

      info "vdc_vnet_plugin initialized..."
    end

    def create_entry(vdc_model_class, vnet_params)
      debug "class = #{vdc_model_class}"
      debug "params = #{vnet_params}"

      vnet_model_class = table[vdc_model_class] || vdc_model_class
      debug vnet_model_class

      case vnet_model_class
      when :NetworkService
        simulated_interface = {}
        simulated_interface[:ipv4_address] = IPAddr.new(vnet_params[:ipv4_address], Socket::AF_INET).to_i
        simulated_interface[:mac_address] = ::Trema::Mac.new(vnet_params[:mac_address]).value
        simulated_interface[:mode] = "simulated"
        simulated_interface[:network_id] = Vnet::Models::Network[vnet_params[:network_uuid]].id
        interface = Vnet::NodeApi.const_get(:Interface).create(simulated_interface)

        vnet_params[:interface_id] = interface.id
        vnet_params[:type] = vnet_params.delete(:name)
        vnet_params.delete(:ipv4_address)
        vnet_params.delete(:mac_address)
        vnet_params.delete(:network_id)
        vnet_params.delete(:network_uuid)
      when :Network
        vnet_params[:ipv4_network] = IPAddr.new(vnet_params[:ipv4_network], Socket::AF_INET).to_i
      when :Interface
        vnet_params[:mac_address] = ::Trema::Mac.new(vnet_params[:mac_address]).value
        vnet_params[:ingress_filtering_enabled] = true
      when :IpLease
        interface_uuid = vnet_params.delete(:interface_uuid)
        interface = Vnet::NodeApi::Interface[interface_uuid]
        vnet_params[:mac_lease_id] = interface.mac_leases.first.id

        network_uuid = vnet_params.delete(:network_uuid)
        network = Vnet::NodeApi::Network[network_uuid]
        vnet_params[:network_id] = network.id

        vnet_params[:ipv4_address] = IPAddr.new(vnet_params[:ipv4_address], Socket::AF_INET).to_i
      end

      debug vnet_params
      Vnet::NodeApi.const_get(vnet_model_class).create(vnet_params)
    end

    def destroy_entry(vdc_model_class, uuid)
      vnet_model_class = table[vdc_model_class] || vdc_model_class
      Vnet::NodeApi.const_get(vnet_model_class).destroy(uuid)
    end
  end
end

Vnet::Plugins::VdcVnetPlugin.supervise_as :vdc_vnet_plugin
