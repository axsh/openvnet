# -*- coding: utf-8 -*-

require 'ipaddr'
require 'trema'
require 'active_support/inflector'

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
        :NetworkRoute => [:TranslationStaticAddress]
      }

      info "vdc_vnet_plugin initialized..."
    end

    def create_entry(vdc_model_class, vnet_params)
      table[vdc_model_class].each do |vnet_model_class|
        send("#{vnet_model_class.to_s.underscore}_params", vnet_params)
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

    def translation_static_address_params(vnet_params)
      outer_network_gateway = find_gw_interface(vnet_params[:outer_network_uuid])
      inner_network_gateway = find_gw_interface(vnet_params[:inner_network_uuid])

      route_link = find_route_link(outer_network_gateway, inner_network_gateway)

      translation = Vnet::NodeApi::Translation.create({
        :mode => 'static_address',
        :passthrough => true
      })

      vnet_params.delete(:outer_network_uuid)
      vnet_params.delete(:inner_network_uuid)
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

    def find_route(gw)
      _gws = Vnet::Models::Route.find_all { |r| r.interface_id == gw.id }

      if _gws.empty?
        warn "no route"
        _gws << create_route(gw)
      end

      _gws.first
    end

    def create_route(gw)
      #TODO
      true
    end

    def find_route_link(gw_a, gw_b)
      r_a = find_route(gw_a)
      r_b = find_route(gw_b)
    end

    def find_gw_interface(network_uuid)
      gateways = Vnet::Models::Interface.find_all { |i|
        i.enable_routing == true && i.mode == 'simulated'
      }.select{ |i|
        i.network.canonical_uuid == network_uuid
      }

      if gateways.empty?
        warn "no gateway interface has been found in the network(#{network_uuid})"
        gateways << create_gw_interface(network_uuid)
      end

      if gateways.size > 1
        warn "multiple gateway interfaces have been detected in the network(#{network_uuid})"
      end

      gateways.first
    end

    def create_gw_interface(network_uuid)
      #TODO
      true
    end
  end
end

Vnet::Plugins::VdcVnetPlugin.supervise_as :vdc_vnet_plugin
