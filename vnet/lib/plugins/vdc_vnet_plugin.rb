# -*- coding: utf-8 -*-

require 'ipaddr'
require 'trema'
require 'active_support/inflector'

module Vnet::Plugins
  class VdcVnetPlugin
    include Celluloid
    include Celluloid::Logger
    include Vnet::Constants::Interface
    include Vnet::Constants::MacAddressPrefix

    attr_reader :table

    def initialize
      @table = {
        # :vdc_model => :vnet_model
        :Network => [:Network, :DatapathNetwork],
        :NetworkVif => [:Interface],
        :NetworkVifIpLease => [:IpAddress, :IpLease],
        :NetworkService => [:NetworkService],
        :NetworkRoute => [:TranslationStaticAddress],
        :NetworkVifSecurityGroup => [:InterfaceSecurityGroup],
        :SecurityGroup => [:SecurityGroup]
      }

      info "vdc_vnet_plugin initialized..."
    end

    def create_entry(vdc_model_class, vnet_params)
      table[vdc_model_class].each do |vnet_model_class|
        send("#{vnet_model_class.to_s.underscore}_params", vnet_params)
      end
    end

    def destroy_entry(vdc_model_class, options)
      debug("destroy_entry #{vdc_model_class} options: #{options}")
      vnet_model_classes = table[vdc_model_class] || [vdc_model_class]

      vnet_model_classes.each do |vnet_model_class|
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
        when :Network
          network = Vnet::NodeApi::Network[options[:uuid]]
          Vnet::NodeApi::DatapathNetwork.filter(network_id: network.id).map { |dpn| dpn.destroy }
          network.destroy
        when :DatapathNetwork
          # Do nothing.
        else
          destroy_entry_by_uuid(vnet_model_class, options[:uuid])
        end
      end
    end

    private

    def security_group_params(vnet_params)
      Vnet::NodeApi::SecurityGroup.create(vnet_params)
    end

    # TODO
    # automatic datapath_network creation fails if no host port entry is on the db.
    # however the datapath_network is necessary entry for packet forwarding on vnet.
    # at lease one host port should be registered in prior to launch the vnet processes.
    def datapath_network_params(vnet_params)

      # TODO refactor
      network = if /^nw-/ =~ vnet_params[:uuid]
                  Vnet::NodeApi::Network[vnet_params[:uuid]]
                else
                  Vnet::NodeApi::Network["nw-#{vnet_params[:uuid]}"]
                end

      Vnet::NodeApi::Datapath.all.each do |datapath|
        # TODO refactor
        host_ports = Vnet::NodeApi::Interface.where({:mode => MODE_HOST, :owner_datapath_id => datapath.id}).all

        host_ports.each do |host_port|
          datapath_network_params = {
            :datapath_id => datapath.id,
            :network_id => network.id,
            :interface_id => host_port.id,
            :ip_lease_id => host_port.ip_leases.first.id
          }
          datapath_network = Vnet::NodeApi::DatapathNetwork.find(datapath_network_params)

          if datapath_network.nil?
            Vnet::NodeApi::DatapathNetwork.create(datapath_network_params.merge({
              :broadcast_mac_address => mac_generate(MAC_ADDRESS_PREFIX_DATAPATH_NETWORK)
            }))
          end
        end
      end
    end

    def network_service_params(vnet_params)
      return unless ['dns', 'dhcp'].include? vnet_params[:name]

      simulated_interface = interface_params(ipv4_address: IPAddr.new(vnet_params[:ipv4_address], Socket::AF_INET).to_i,
                                            mac_address: vnet_params[:mac_address],
                                            mode: MODE_SIMULATED,
                                            network_id: Vnet::NodeApi::Network[vnet_params[:network_uuid]].id)

      params = {
        :interface_id => simulated_interface.id,
        :type => vnet_params[:name]
      }
      ns = Vnet::NodeApi::NetworkService.find(params)
      if ns.nil?
        Vnet::NodeApi::NetworkService.create(params)
      end
      ns
    end

    def network_params(vnet_params)
      network = Vnet::NodeApi::Network[vnet_params[:uuid]]
      if network
        info "network #{vnet_params[:uuid]} already exists as #{network.canonical_uuid}"
        return
      end

      vnet_params[:ipv4_network] = IPAddr.new(vnet_params[:ipv4_network], Socket::AF_INET).to_i

      Vnet::NodeApi::Network.create(vnet_params)
    end

    def interface_params(vnet_params)
      vnet_params[:mac_address] = ::Trema::Mac.new(vnet_params[:mac_address]).value if vnet_params[:mac_address]

      interface = if vnet_params[:ipv4_address] && vnet_params[:mac_address]
                    Vnet::NodeApi::Interface.find_all {|i|
                      i.ipv4_address == vnet_params[:ipv4_address] &&
                      i.mac_address == vnet_params[:mac_address]
                    }
                  elsif vnet_params[:uuid]
                    Vnet::NodeApi::Interface[vnet_params[:uuid]]
                  else
                    Vnet::NodeApi::Interface.find(vnet_params)
                  end

      if interface.nil?
        interface = Vnet::NodeApi::Interface.create(vnet_params)
      end
      interface
    end

    def ip_lease_params(vnet_params)
      if vnet_params.has_key? :mac_lease_id
        mac_lease_id = vnet_params[:mac_lease_id]
      elsif vnet_params.has_key? :interface_uuid
        mac_lease_id = Vnet::NodeApi::Interface[vnet_params[:interface_uuid]].mac_leases.first.id
      else
        return
      end

      if vnet_params.has_key? :ip_address_id
        ip_address_id = vnet_params[:ip_address_id]
      elsif vnet_params.has_key? :ipv4_address
        ip_address_id = ip_address_params(
          ipv4_address: vnet_params[:ipv4_address],
          network_id: Vnet::NodeApi::Network[vnet_params[:network_uuid]].id).id
      else
        return
      end

      if vnet_params.has_key? :interface_id
        interface_id = vnet_params[:interface_id]
      elsif vnet_params.has_key? :interface_uuid
        interface_id = Vnet::NodeApi::Interface[vnet_params[:interface_uuid]].id
      else
        return
      end

      enable_routing = if vnet_params.has_key? :enable_routing
                         vnet_params[:enable_routing]
                       else
                         false
                       end

      params = {
        :mac_lease_id => mac_lease_id,
        :ip_address_id => ip_address_id,
        :interface_id => interface_id,
        :enable_routing => enable_routing
      }

      ip_lease = Vnet::NodeApi::IpLease.find(params)
      if ip_lease.nil?
        Vnet::NodeApi::IpLease.create(params)
      end

      ip_lease
    end

    def ip_address_params(vnet_params)
      ipv4_address = vnet_params[:ipv4_address] || return
      if vnet_params.has_key? :network_id
        network_id = vnet_params[:network_id]
      elsif vnet_params.has_key? :network_uuid
        network_id = Vnet::NodeApi::Network[vnet_params[:network_uuid]].id
      else
        return
      end

      ipaddr = IPAddr.new(ipv4_address).to_i

      ip_address = Vnet::NodeApi::IpAddress.find(:ipv4_address => ipaddr, :network_id => network_id)
      if ip_address.nil?
        ip_address = Vnet::NodeApi::IpAddress.create({
          :ipv4_address => ipaddr,
          :network_id => network_id
        })
      end

      ip_address
    end

    def interface_security_group_params(vnet_params)
      vnet_params = {
        interface_id: Vnet::NodeApi::Interface[vnet_params[:interface_uuid]].id,
        security_group_id: Vnet::NodeApi::SecurityGroup[vnet_params[:security_group_uuid]].id
      }
      Vnet::NodeApi::InterfaceSecurityGroup.create(vnet_params)
    end

    def translation_static_address_params(vnet_params)
      outer_network_gateway = find_gw_interface(vnet_params[:outer_network_uuid], vnet_params[:outer_network_gw])
      inner_network_gateway = find_gw_interface(vnet_params[:inner_network_uuid], vnet_params[:inner_network_gw])

      ip_address = ip_address_params(ipv4_address: vnet_params[:ingress_ipv4_address], network_id: outer_network_gateway.ip_leases.first.network.id)

      ip_lease_for_nat_ip = ip_lease_params(mac_lease_id: outer_network_gateway.mac_leases.first.id,
                                            ip_address_id: ip_address.id,
                                            interface_id: outer_network_gateway.id,
                                            enable_routing: true)

      route_link = find_route_link(outer_network_gateway, inner_network_gateway)

      host_ports = Vnet::NodeApi::Interface.where(:mode => MODE_HOST).all
      host_ports.each do |host_port|
        dprl_params = {
          :datapath_id => Vnet::NodeApi::ActiveInterface.find({:interface_id => host_port.id}).datapath_id,
          :interface_id => host_port.id,
          :mac_address_id => mac_model_generate(MAC_ADDRESS_PREFIX_DATAPATH_ROUTE_LINK).id,
          :route_link_id => route_link.id
        }
        unless Vnet::NodeApi::DatapathRouteLink.find(dprl_params)
          Vnet::NodeApi::DatapathRouteLink.create(dprl_params)
        end
      end

      translation_params = {
        :interface_id => outer_network_gateway.id,
        :mode => 'static_address',
        :passthrough => true
      }
      unless translation = Vnet::NodeApi::Translation.find(translation_params)
        translation = Vnet::NodeApi::Translation.create(translation_params)
      end

      vnet_params[:route_link_id] = route_link.id

      ing = vnet_params[:ingress_ipv4_address]
      eg = vnet_params[:egress_ipv4_address]
      vnet_params[:ingress_ipv4_address] = IPAddr.new(ing).to_i
      vnet_params[:egress_ipv4_address] = IPAddr.new(eg).to_i
      vnet_params[:translation_id] = translation.id

      vnet_params.delete(:outer_network_uuid)
      vnet_params.delete(:inner_network_uuid)
      vnet_params.delete(:outer_network_gw)
      vnet_params.delete(:inner_network_gw)

      Vnet::NodeApi::TranslationStaticAddress.create(vnet_params)
    end

    def find_route(gw)
      Vnet::NodeApi::Route.find_all { |r| r.interface_id == gw.id }
    end

    def create_route(route_link, gw)
      #TODO
      ipv4_network, ipv4_prefix = case gw.network.canonical_uuid
                                  when 'nw-public' then [0, 0]
                                  else
                                    [gw.network.ipv4_network, gw.network.ipv4_prefix]
                                  end
      params = {
        :interface_id => gw.id,
        :route_link_id => route_link.id,
        :network_id => gw.network.id,
        :ipv4_network => ipv4_network,
        :ipv4_prefix => ipv4_prefix
      }
      Vnet::NodeApi::Route.create(params)
    end

    def x
      "#{rand(16).to_s(16)}#{rand(16).to_s(16)}"
    end

    def mac_model_generate(prefix = nil)
      Vnet::NodeApi::MacAddress.create({
        :mac_address => mac_generate(prefix)
      })
    end

    def mac_generate(prefix = nil)
      mac = if prefix
              "#{prefix}:#{x}:#{x}:#{x}"
            else
              "#{x}:#{x}:#{x}:#{x}:#{x}:#{x}"
            end

      ::Trema::Mac.new(mac).value
    end

    def create_route_link(gw_a, gw_b)
      route_link = Vnet::NodeApi::RouteLink.create({
        :mac_address_id => mac_model_generate(MAC_ADDRESS_PREFIX_ROUTE_LINK).id
      })
      create_route(route_link, gw_a)
      create_route(route_link, gw_b)
      route_link
    end

    def find_route_link(gw_a, gw_b)
      r_a = find_route(gw_a)
      r_b = find_route(gw_b)

      route_link = find_pair(r_a, r_b)

      if route_link.nil?
        route_link = create_route_link(gw_a, gw_b)
      end

      route_link
    end

    def find_pair(r_a, r_b)
      r_a.each do |ra|
        r_b.each do |rb|
          return ra.route_link if ra.route_link.uuid == rb.route_link.uuid
        end
      end
      nil
    end

    def find_gw_interface(network_uuid, ipv4_gw)
      gateways = Vnet::NodeApi::Interface.find_all { |i|
        i.enable_routing == true && i.mode == MODE_SIMULATED
      }.select{ |i|
        i.network && i.network.canonical_uuid == network_uuid
      }

      if gateways.empty?
        info "no gateway interface has been found in the network(#{network_uuid})... create a gateway interface"
        gateways << create_gw_interface(network_uuid, ipv4_gw)
      end

      if gateways.size > 1
        info "multiple gateway interfaces have been detected in the network(#{network_uuid})"
      end

      gateways.first
    end

    def create_gw_interface(network_uuid, ipv4_gw)
      params = {
        :mode => MODE_SIMULATED,
        :display_name => "gw_#{network_uuid}",
        :mac_address => mac_generate(MAC_ADDRESS_PREFIX_GW),
        :enable_routing => true,
        :enable_route_translation => false
      }
      interface = Vnet::NodeApi::Interface.create(params)

      network = Vnet::NodeApi::Network[network_uuid]
      if network.nil?
        error "network uuid #{network_uuid} not found"
        return
      end

      ip_address = ip_address_params(ipv4_address: ipv4_gw, network_id: network.id)

      ip_lease_params(ip_address_id: ip_address.id,
                      mac_lease_id: interface.mac_leases.first.id,
                      interface_id: interface.id,
                      enable_routing: false)

      interface
    end

    def destroy_entry_by_uuid(klass, uuid)
      Vnet::NodeApi.const_get(klass).destroy(uuid)
    end
  end
end

Vnet::Plugins::VdcVnetPlugin.supervise_as :vdc_vnet_plugin
