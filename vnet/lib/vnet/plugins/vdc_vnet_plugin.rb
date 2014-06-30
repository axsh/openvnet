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
        :NetworkVifSecurityGroup => :InterfaceSecurityGroup
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
      when :InterfaceSecurityGroup
        vnet_params = {
          interface_id: Vnet::NodeApi::Interface[vnet_params[:interface_uuid]].id,
          security_group_id: Vnet::NodeApi::SecurityGroup[vnet_params[:security_group_uuid]].id
        }
      end

      debug vnet_params
      Vnet::NodeApi.const_get(vnet_model_class).create(vnet_params)
    end

    def destroy_entry(vdc_model_class, options)
      debug("destroy_entry #{vdc_model_class} options: #{options}")
      vnet_model_class = table[vdc_model_class] || vdc_model_class

      case vnet_model_class
      when :IpLease
        network = Vnet::NodeApi::Network[options[:network_uuid]]
        ip_address = Vnet::NodeApi::IpAddress.filter(
          network_id: network.id, 
          ipv4_address: options[:ipv4_address]
        ).first
        interface = Vnet::NodeApi::Interface[options[:interface_uuid]]
        ip_lease = Vnet::NodeApi::IpLease.filter(
          interface_id: interface.id,
          ip_address_id: ip_address.id
        ).first
        Vnet::NodeApi::IpLease.execute(:destroy, ip_lease.canonical_uuid)
      when :InterfaceSecurityGroup  
        security_group = Vnet::NodeApi::SecurityGroup[options[:security_group_uuid]]
        interface = Vnet::NodeApi::Interface[options[:interface_uuid]]
        interface_security_group = Vnet::NodeApi::InterfaceSecurityGroup.filter(
          security_group_id: security_group.id,
          interface_id: interface.id
        ).first
        Vnet::NodeApi::InterfaceSecurityGroup.execute(:destroy, interface_security_group.canonical_uuid)
      else
        destroy_entry_by_uuid(vnet_model_class, options)
      end
    end

    private

    def destroy_entry_by_uuid(klass, uuid)
      Vnet::NodeApi.const_get(klass).destroy(uuid)
    end
  end
end

Vnet::Plugins::VdcVnetPlugin.supervise_as :vdc_vnet_plugin
