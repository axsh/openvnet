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
        # :vdc_model => :vnet_model
        :Network => [:Network],
        :NetworkVif => [:Interface],
        :NetworkVifIpLease => [:IpLease],
        :NetworkService => [:NetworkService],
        :NetworkRoute => [:LeasePolicy, :IpLeaseContainer, :IpLease]
      }

      info "vdc_vnet_plugin initialized..."
    end

    def create_entry(vdc_model_class, vnet_params)
      table[vdc_model_class].each do |vnet_model_class|
        send("#{vnet_model_class.underscore}_params", vnet_params)
        Vnet::NodeApi.const_get(vnet_model_class).create(vnet_params)
      end
    end

    def destroy_entry(vdc_model_class, uuid)
      vnet_model_class = table[vdc_model_class]
      Vnet::NodeApi.const_get(vnet_model_class).destroy(uuid)
    end

    private

    def network_service_params(vnet_params)
      si_params = simulated_interface_params(vnet_params)

      if si_params[:network_id].nil?
        info "#{vnet_params[:network_uuid]} does not exist on vnet"
        return
      end

      interface = Vnet::NodeApi.const_get(:Interface).create(si_params)

      vnet_params[:interface_id] = interface.id
      vnet_params[:type] = vnet_params.delete(:name)

      vnet_params.delete(:ipv4_address)
      vnet_params.delete(:mac_address)
      vnet_params.delete(:network_id)
      vnet_params.delete(:network_uuid)
    end

    def network_params(vnet_params)
      vnet_params[:ipv4_network] = IPAddr.new(vnet_params[:ipv4_network], Socket::AF_INET).to_i
    end

    def interface_params(vnet_params)
      vnet_params[:mac_address] = ::Trema::Mac.new(vnet_params[:mac_address]).value
    end

    def ip_lease_params(vnet_params)
      interface_uuid = vnet_params.delete(:interface_uuid)
      interface = Vnet::NodeApi::Interface[interface_uuid]
      vnet_params[:mac_lease_id] = interface.mac_leases.first.id

      network_uuid = vnet_params.delete(:network_uuid)
      network = Vnet::NodeApi::Network[network_uuid]
      vnet_params[:network_id] = network.id

      vnet_params[:ipv4_address] = IPAddr.new(vnet_params[:ipv4_address], Socket::AF_INET).to_i
    end

    def lease_policy_params(vnet_params)
    end

    def ip_lease_container_params(vnet_params)
    end

    def simulated_interface_params(vnet_params)
      network = Vnet::Models::Network[vnet_params[:network_uuid]]

      {
        :ipv4_address => IPAddr.new(vnet_params[:ipv4_address], Socket::AF_INET).to_i,
        :mac_address => ::Trema::Mac.new(vnet_params[:mac_address]).value,
        :mode => "simulated",
        :network_id => network && network.id
      }
    end
  end
end

Vnet::Plugins::VdcVnetPlugin.supervise_as :vdc_vnet_plugin
