# -*- coding: utf-8 -*-

#require 'active_support/all'
#require 'active_support/core_ext'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/object'
require 'active_support/hash_with_indifferent_access'
require 'active_support/inflector'
require 'ext/kernel'
require 'fuguta'
require 'json'
require 'logger'

module Vnet

  ROOT = ENV['VNET_ROOT'] || File.expand_path('../../', __FILE__)
  CONFIG_PATH = ["/etc/openvnet", "/etc/wakame-vnet"].unshift(ENV['CONFIG_PATH']).compact
  LOG_DIRECTORY = ENV['LOG_DIRECTORY'] || "/var/log/openvnet"

  class << self
    attr_accessor :logger
  end

  autoload :Event,                'vnet/event'
  autoload :ItemBase,             'vnet/item_base'
  autoload :ItemVnetBase,         'vnet/item_base'
  autoload :ItemDpBase,           'vnet/item_base'
  autoload :ItemDpUuid,           'vnet/item_base'
  autoload :Manager,              'vnet/manager'
  autoload :LookupParams,         'vnet/manager_modules'
  autoload :UpdateItemStates,     'vnet/manager_modules'
  autoload :UpdatePropertyStates, 'vnet/manager_modules'

  module Configurations
    autoload :Base,   'vnet/configurations/base'
    autoload :Common, 'vnet/configurations/common'
    autoload :Webapi, 'vnet/configurations/webapi'
    autoload :Vnmgr,  'vnet/configurations/vnmgr'
    autoload :Vna,    'vnet/configurations/vna'
  end

  module Constants
    autoload :Interface, 'vnet/constants/interface'
    autoload :LeasePolicy, 'vnet/constants/lease_policy'
    autoload :MacAddressPrefix, 'vnet/constants/mac_address_prefix'
    autoload :Network, 'vnet/constants/network'
    autoload :NetworkService, 'vnet/constants/network_service'
    autoload :Openflow, 'vnet/constants/openflow'
    autoload :OpenflowFlows, 'vnet/constants/openflow_flows'
    autoload :Translation, 'vnet/constants/translation'
    autoload :VnetAPI, 'vnet/constants/vnet_api'
  end

  module Core
    autoload :ActiveInterfaceEvents, 'vnet/core/event_helpers'
    autoload :ActiveNetworkEvents, 'vnet/core/event_helpers'
    autoload :ActivePortEvents, 'vnet/core/event_helpers'
    autoload :ActiveRouteLinkEvents, 'vnet/core/event_helpers'
    autoload :DpInfo, 'vnet/core/dp_info'

    autoload :ActiveInterface, 'vnet/core/items'
    autoload :ActiveInterfaceManager, 'vnet/core/active_interface_manager'
    autoload :ActiveNetwork, 'vnet/core/items'
    autoload :ActiveNetworkManager, 'vnet/core/active_network_manager'

    autoload :AddressHelpers, 'vnet/core/address_helpers'
    autoload :ConnectionManager, 'vnet/core/connection_manager'
    autoload :Datapath, 'vnet/core/items'
    autoload :DatapathManager, 'vnet/core/datapath_manager'
    autoload :FilterManager, 'vnet/core/filter_manager'
    autoload :HostDatapath, 'vnet/core/host_datapath'
    autoload :HostDatapathManager, 'vnet/core/host_datapath_manager'
    autoload :Interface, 'vnet/core/interface'
    autoload :InterfaceManager, 'vnet/core/interface_manager'
    autoload :InterfacePort, 'vnet/core/interface_port'
    autoload :InterfacePortManager, 'vnet/core/interface_port_manager'
    autoload :Manager, 'vnet/core/manager'
    autoload :Network, 'vnet/core/items'
    autoload :NetworkManager, 'vnet/core/network_manager'
    autoload :Port, 'vnet/core/port'
    autoload :PortManager, 'vnet/core/port_manager'
    autoload :Route, 'vnet/core/items'
    autoload :RouteManager, 'vnet/core/route_manager'
    autoload :Router, 'vnet/core/items'
    autoload :RouterManager, 'vnet/core/router_manager'
    autoload :Service, 'vnet/core/service'
    autoload :ServiceManager, 'vnet/core/service_manager'
    autoload :Translation, 'vnet/core/items'
    autoload :TranslationManager, 'vnet/core/translation_manager'
    autoload :Tunnel, 'vnet/core/tunnel'
    autoload :TunnelManager, 'vnet/core/tunnel_manager'

    module ActiveInterfaces
      autoload :Base, 'vnet/core/active_interfaces/base'
      autoload :Local, 'vnet/core/active_interfaces/local'
      autoload :Remote, 'vnet/core/active_interfaces/remote'
    end

    module ActiveNetworks
      autoload :Base, 'vnet/core/active_networks/base'
      autoload :Local, 'vnet/core/active_networks/local'
      autoload :Remote, 'vnet/core/active_networks/remote'
    end

    module Connections
      autoload :Base, 'vnet/core/connections/base'
      autoload :TCP, 'vnet/core/connections/tcp'
      autoload :UDP, 'vnet/core/connections/udp'
    end

    module Datapaths
      autoload :Base, 'vnet/core/datapaths/base'
      autoload :Host, 'vnet/core/datapaths/host'
      autoload :Remote, 'vnet/core/datapaths/remote'
    end

    module Filters
      autoload :AcceptAllTraffic, 'vnet/core/filters/accept_all_traffic'
      autoload :AcceptIngressArp, 'vnet/core/filters/accept_ingress_arp'
      autoload :Base, 'vnet/core/filters/base'
      autoload :Cookies, 'vnet/core/filters/cookies'
      autoload :SecurityGroup, 'vnet/core/filters/security_group'
    end

    module HostDatapaths
      autoload :Base, 'vnet/core/host_datapaths/base'
    end

    module Interfaces
      autoload :Base, 'vnet/core/interfaces/base'
      autoload :Edge, 'vnet/core/interfaces/edge'
      autoload :Host, 'vnet/core/interfaces/host'
      autoload :IfBase, 'vnet/core/interfaces/if_base'
      autoload :Internal, 'vnet/core/interfaces/internal'
      autoload :Patch, 'vnet/core/interfaces/patch'
      autoload :Simulated, 'vnet/core/interfaces/simulated'
      autoload :Vif, 'vnet/core/interfaces/vif'
    end

    module InterfacePorts
      autoload :Base, 'vnet/core/interface_ports/base'
    end

    module Networks
      autoload :Base, 'vnet/core/networks/base'
      autoload :Internal, 'vnet/core/networks/internal'
      autoload :Physical, 'vnet/core/networks/physical'
      autoload :Virtual, 'vnet/core/networks/virtual'
    end

    module Ports
      autoload :Base, 'vnet/core/ports/base'
      autoload :Generic, 'vnet/core/ports/generic'
      autoload :Host, 'vnet/core/ports/host'
      autoload :Local, 'vnet/core/ports/local'
      autoload :Tunnel, 'vnet/core/ports/tunnel'
      autoload :Vif, 'vnet/core/ports/vif'
    end

    module Routes
      autoload :Base, 'vnet/core/routes/base'
    end

    module Routers
      autoload :Base, 'vnet/core/routers/base'
      autoload :RouteLink, 'vnet/core/routers/route_link'
    end

    module Services
      autoload :Base, 'vnet/core/services/base'
      autoload :Dhcp, 'vnet/core/services/dhcp'
      autoload :Dns, 'vnet/core/services/dns'
      autoload :Router, 'vnet/core/services/router'
    end

    module Translations
      autoload :Base, 'vnet/core/translations/base'
      autoload :StaticAddress, 'vnet/core/translations/static_address'
      autoload :VnetEdgeHandler, 'vnet/core/translations/vnet_edge_handler'
    end

    module Tunnels
      autoload :Base, 'vnet/core/tunnels/base'
      autoload :Gre, 'vnet/core/tunnels/gre'
      autoload :Mac2Mac, 'vnet/core/tunnels/mac2mac'
      autoload :Unknown, 'vnet/core/tunnels/unknown'
    end

  end

  module Event
    autoload :EventTasks, 'vnet/event/event_tasks'
    autoload :Dispatchable, 'vnet/event/dispatchable'
    autoload :Notifications, 'vnet/event/notifications'
  end

  module Helpers
    autoload :SecurityGroup, 'vnet/helpers/security_group'
    autoload :Event, 'vnet/helpers/event'
  end

  module Endpoints
    autoload :Errors, 'vnet/endpoints/errors'
    autoload :ResponseGenerator, 'vnet/endpoints/response_generator'
    autoload :CollectionResponseGenerator, 'vnet/endpoints/response_generator'

    module V10
      autoload :Helpers, 'vnet/endpoints/1.0/helpers'
      autoload :VnetAPI, 'vnet/endpoints/1.0/vnet_api'

      module Responses
        autoload :Datapath, 'vnet/endpoints/1.0/responses/datapath'
        autoload :DatapathNetwork, 'vnet/endpoints/1.0/responses/datapath_network'
        autoload :DatapathRouteLink, 'vnet/endpoints/1.0/responses/datapath_route_link'
        autoload :DnsService, 'vnet/endpoints/1.0/responses/dns_service'
        autoload :DnsRecord, 'vnet/endpoints/1.0/responses/dns_record'
        autoload :Interface, 'vnet/endpoints/1.0/responses/interface'
        autoload :InterfacePort, 'vnet/endpoints/1.0/responses/interface_port'
        autoload :IpAddress, 'vnet/endpoints/1.0/responses/ip_address'
        autoload :IpLease, 'vnet/endpoints/1.0/responses/ip_lease'
        autoload :IpLeaseContainer, 'vnet/endpoints/1.0/responses/ip_lease_container'
        autoload :IpRange, 'vnet/endpoints/1.0/responses/ip_range'
        autoload :IpRangeGroup, 'vnet/endpoints/1.0/responses/ip_range_group'
        autoload :IpRetention, 'vnet/endpoints/1.0/responses/ip_retention'
        autoload :IpRetentionContainer, 'vnet/endpoints/1.0/responses/ip_retention_container'
        autoload :LeasePolicy, 'vnet/endpoints/1.0/responses/lease_policy'
        autoload :MacAddress, 'vnet/endpoints/1.0/responses/mac_address'
        autoload :MacLease, 'vnet/endpoints/1.0/responses/mac_lease'
        autoload :Network, 'vnet/endpoints/1.0/responses/network'
        autoload :NetworkService, 'vnet/endpoints/1.0/responses/network_service'
        autoload :Route, 'vnet/endpoints/1.0/responses/route'
        autoload :RouteLink, 'vnet/endpoints/1.0/responses/route_link'
        autoload :SecurityGroup, 'vnet/endpoints/1.0/responses/security_group'
        autoload :Translation, 'vnet/endpoints/1.0/responses/translation'
        autoload :TranslationStaticAddress, 'vnet/endpoints/1.0/responses/translation_static_address'
        autoload :VlanTranslation, 'vnet/endpoints/1.0/responses/vlan_translation'

        autoload :DatapathCollection, 'vnet/endpoints/1.0/responses/datapath'
        autoload :DatapathNetworkCollection, 'vnet/endpoints/1.0/responses/datapath_network'
        autoload :DatapathRouteLinkCollection, 'vnet/endpoints/1.0/responses/datapath_route_link'
        autoload :DnsServiceCollection, 'vnet/endpoints/1.0/responses/dns_service'
        autoload :DnsRecordCollection, 'vnet/endpoints/1.0/responses/dns_record'
        autoload :InterfaceCollection, 'vnet/endpoints/1.0/responses/interface'
        autoload :InterfacePortCollection, 'vnet/endpoints/1.0/responses/interface_port'
        autoload :IpAddressCollection, 'vnet/endpoints/1.0/responses/ip_address'
        autoload :IpLeaseCollection, 'vnet/endpoints/1.0/responses/ip_lease'
        autoload :IpLeaseContainerCollection, 'vnet/endpoints/1.0/responses/ip_lease_container'
        autoload :IpRangeCollection, 'vnet/endpoints/1.0/responses/ip_range'
        autoload :IpRangeGroupCollection, 'vnet/endpoints/1.0/responses/ip_range_group'
        autoload :IpRetentionCollection, 'vnet/endpoints/1.0/responses/ip_retention'
        autoload :IpRetentionContainerCollection, 'vnet/endpoints/1.0/responses/ip_retention_container'
        autoload :LeasePolicyCollection, 'vnet/endpoints/1.0/responses/lease_policy'
        autoload :MacAddressCollection, 'vnet/endpoints/1.0/responses/mac_address'
        autoload :MacLeaseCollection, 'vnet/endpoints/1.0/responses/mac_lease'
        autoload :NetworkCollection, 'vnet/endpoints/1.0/responses/network'
        autoload :NetworkServiceCollection, 'vnet/endpoints/1.0/responses/network_service'
        autoload :RouteCollection, 'vnet/endpoints/1.0/responses/route'
        autoload :RouteLinkCollection, 'vnet/endpoints/1.0/responses/route_link'
        autoload :SecurityGroupCollection, 'vnet/endpoints/1.0/responses/security_group'
        autoload :TranslationCollection, 'vnet/endpoints/1.0/responses/translation'
        autoload :VlanTranslationCollection, 'vnet/endpoints/1.0/responses/vlan_translation'
      end
    end
  end

  module Initializers
    autoload :DB, 'vnet/initializers/db'
    autoload :Logger, 'vnet/initializers/logger'
  end

  module Models
    class InvalidUUIDError < StandardError; end

    autoload :ActiveInterface, 'vnet/models/active_interface'
    autoload :ActiveNetwork, 'vnet/models/active_network'
    autoload :Base, 'vnet/models/base'
    autoload :Datapath, 'vnet/models/datapath'
    autoload :DatapathNetwork, 'vnet/models/datapath_network'
    autoload :DatapathRouteLink, 'vnet/models/datapath_route_link'
    autoload :DnsService, 'vnet/models/dns_service'
    autoload :DnsRecord, 'vnet/models/dns_record'
    autoload :Interface, 'vnet/models/interface'
    autoload :InterfacePort, 'vnet/models/interface_port'
    autoload :IpAddress, 'vnet/models/ip_address'
    autoload :IpLease, 'vnet/models/ip_lease'
    autoload :IpLeaseContainer, 'vnet/models/ip_lease_container'
    autoload :IpLeaseContainerIpLease, 'vnet/models/ip_lease_container_ip_lease'
    autoload :IpRange, 'vnet/models/ip_range'
    autoload :IpRangeGroup, 'vnet/models/ip_range_group'
    autoload :IpRetention, 'vnet/models/ip_retention'
    autoload :IpRetentionContainer, 'vnet/models/ip_retention_container'
    autoload :LeasePolicy, 'vnet/models/lease_policy'
    autoload :LeasePolicyBaseNetwork, 'vnet/models/lease_policy_base_network'
    autoload :LeasePolicyBaseInterface, 'vnet/models/lease_policy_base_interface'
    autoload :LeasePolicyIpLeaseContainer, 'vnet/models/lease_policy_ip_lease_container'
    autoload :LeasePolicyIpRetentionContainer, 'vnet/models/lease_policy_ip_retention_container'
    autoload :MacAddress, 'vnet/models/mac_address'
    autoload :MacLease, 'vnet/models/mac_lease'
    autoload :MacRange, 'vnet/models/mac_range'
    autoload :MacRangeGroup, 'vnet/models/mac_range_group'
    autoload :Network, 'vnet/models/network'
    autoload :NetworkService, 'vnet/models/network_service'
    autoload :Route, 'vnet/models/route'
    autoload :RouteLink, 'vnet/models/route_link'
    autoload :SecurityGroup, 'vnet/models/security_group'
    autoload :SecurityGroupInterface, 'vnet/models/security_group_interface'
    autoload :Taggable, 'vnet/models/base'
    autoload :Translation, 'vnet/models/translation'
    autoload :TranslationStaticAddress, 'vnet/models/translation_static_address'
    autoload :Tunnel, 'vnet/models/tunnel'
    autoload :VlanTranslation, 'vnet/models/vlan_translation'
  end

  module ModelWrappers
    autoload :ActiveInterface, 'vnet/model_wrappers/wrappers'
    autoload :ActiveNetwork, 'vnet/model_wrappers/wrappers'
    autoload :Base, 'vnet/model_wrappers/base'
    autoload :Datapath, 'vnet/model_wrappers/datapath'
    autoload :DatapathNetwork, 'vnet/model_wrappers/datapath_network'
    autoload :DatapathRouteLink, 'vnet/model_wrappers/datapath_route_link'
    autoload :DnsService, 'vnet/model_wrappers/dns_service'
    autoload :DnsRecord, 'vnet/model_wrappers/dns_record'
    autoload :Helpers, 'vnet/model_wrappers/helpers'
    autoload :Interface, 'vnet/model_wrappers/interface'
    autoload :InterfacePort, 'vnet/model_wrappers/interface_port'
    autoload :IpAddress, 'vnet/model_wrappers/ip_address'
    autoload :IpLease, 'vnet/model_wrappers/ip_lease'
    autoload :IpLeaseContainer, 'vnet/model_wrappers/ip_lease_container'
    autoload :IpLeaseContainerIpLease, 'vnet/model_wrappers/ip_lease_container_ip_lease'
    autoload :IpRange, 'vnet/model_wrappers/wrappers'
    autoload :IpRangeGroup, 'vnet/model_wrappers/wrappers'
    autoload :IpRetention, 'vnet/model_wrappers/ip_retention'
    autoload :IpRetentionContainer, 'vnet/model_wrappers/ip_retention_container'
    autoload :LeasePolicy, 'vnet/model_wrappers/lease_policy'
    autoload :LeasePolicyBaseNetwork, 'vnet/model_wrappers/lease_policy'
    autoload :LeasePolicyBaseInterface, 'vnet/model_wrappers/lease_policy'
    autoload :LeasePolicyIpLeaseContainer, 'vnet/model_wrappers/lease_policy_ip_lease_container'
    autoload :LeasePolicyIpRetentionContainer, 'vnet/model_wrappers/lease_policy_ip_retention_container'
    autoload :MacAddress, 'vnet/model_wrappers/mac_address'
    autoload :MacLease, 'vnet/model_wrappers/mac_lease'
    autoload :MacRange, 'vnet/model_wrappers/wrappers'
    autoload :MacRangeGroup, 'vnet/model_wrappers/wrappers'
    autoload :Network, 'vnet/model_wrappers/network'
    autoload :NetworkService, 'vnet/model_wrappers/network_service'
    autoload :Route, 'vnet/model_wrappers/route'
    autoload :RouteLink, 'vnet/model_wrappers/route_link'
    autoload :SecurityGroup, 'vnet/model_wrappers/security_group'
    autoload :SecurityGroupInterface, 'vnet/model_wrappers/security_group_interface'
    autoload :Translation, 'vnet/model_wrappers/translation'
    autoload :TranslationStaticAddress, 'vnet/model_wrappers/translation'
    autoload :Tunnel, 'vnet/model_wrappers/tunnel'
    autoload :VlanTranslation, 'vnet/model_wrappers/vlan_translation'
  end

  autoload :NodeApi, 'vnet/node_api'
  module NodeApi
    autoload :RpcProxy, 'vnet/node_api/proxies'
    autoload :DirectProxy, 'vnet/node_api/proxies'

    autoload :Base, 'vnet/node_api/base'
    autoload :EventBase, 'vnet/node_api/event_base'

    autoload :ActiveInterface, 'vnet/node_api/active_interface'
    autoload :ActiveNetwork, 'vnet/node_api/active_network'
    autoload :Datapath, 'vnet/node_api/datapath.rb'
    autoload :DatapathGeneric, 'vnet/node_api/datapath_generic.rb'
    autoload :DatapathNetwork, 'vnet/node_api/datapath_generic.rb'
    autoload :DatapathRouteLink, 'vnet/node_api/datapath_generic.rb'
    autoload :DnsService, 'vnet/node_api/dns_service'
    autoload :DnsRecord, 'vnet/node_api/dns_record'
    autoload :Interface, 'vnet/node_api/interface.rb'
    autoload :InterfacePort, 'vnet/node_api/interface_port.rb'
    autoload :IpAddress, 'vnet/node_api/models.rb'
    autoload :IpLease, 'vnet/node_api/ip_lease.rb'
    autoload :IpLeaseContainer, 'vnet/node_api/ip_lease_container'
    autoload :IpRange, 'vnet/node_api/models.rb'
    autoload :IpRangeGroup, 'vnet/node_api/models.rb'
    autoload :IpRetention, 'vnet/node_api/ip_retention'
    autoload :IpRetentionContainer, 'vnet/node_api/ip_retention_container'
    autoload :LeasePolicy, 'vnet/node_api/lease_policy.rb'
    autoload :LeasePolicyBaseInterface, 'vnet/node_api/models.rb'
    autoload :LeasePolicyBaseNetwork, 'vnet/node_api/models.rb'
    autoload :MacAddress, 'vnet/node_api/models.rb'
    autoload :MacLease, 'vnet/node_api/mac_lease.rb'
    autoload :MacRange, 'vnet/node_api/models.rb'
    autoload :MacRangeGroup, 'vnet/node_api/models.rb'
    autoload :Network, 'vnet/node_api/network.rb'
    autoload :NetworkService, 'vnet/node_api/network_service.rb'
    autoload :Route, 'vnet/node_api/route.rb'
    autoload :RouteLink, 'vnet/node_api/route_link.rb'
    autoload :SecurityGroup, 'vnet/node_api/security_group'
    autoload :SecurityGroupInterface, 'vnet/node_api/security_group_interface'
    autoload :Translation, 'vnet/node_api/translation.rb'
    autoload :TranslationStaticAddress, 'vnet/node_api/translation_static_address.rb'
    autoload :Tunnel, 'vnet/node_api/tunnel.rb'
    autoload :VlanTranslation, 'vnet/node_api/translation.rb'
  end

  module NodeModules
    autoload :Rpc, 'vnet/node_modules/rpc'
    autoload :EventHandler, 'vnet/node_modules/event_handler'
    autoload :ServiceOpenflow, 'vnet/node_modules/service_openflow'
    autoload :SwitchManager, 'vnet/node_modules/service_openflow'
  end

  module Openflow
    autoload :ArpLookup, 'vnet/openflow/arp_lookup'
    autoload :Controller, 'vnet/openflow/controller'
    autoload :Datapath, 'vnet/openflow/datapath'
    autoload :DatapathInfo, 'vnet/openflow/datapath'
    autoload :Flow, 'vnet/openflow/flow'
    autoload :FlowHelpers, 'vnet/openflow/flow_helpers'
    autoload :MetadataHelpers, 'vnet/openflow/metadata_helpers'
    autoload :OvsOfctl, 'vnet/openflow/ovs_ofctl'
    autoload :PacketHelpers, 'vnet/openflow/packet_handler'
    autoload :Switch, 'vnet/openflow/switch'
    autoload :TremaTasks, 'vnet/openflow/trema_tasks'
  end

  module Plugins
    autoload :VdcVnetPlugin, 'plugins/vdc_vnet_plugin'
  end

  module Services
    autoload :IpRetentionContainerManager, 'vnet/services/ip_retention_container_manager'
    autoload :LeasePolicy, 'vnet/services/lease_policy'
    autoload :LeasePolicyManager, 'vnet/services/lease_policy_manager'
    autoload :VnetInfo, 'vnet/services/vnet_info'
    autoload :Vnmgr, 'vnet/services/vnmgr'

    module IpRetentionContainers
      autoload :Base, 'vnet/services/ip_retention_containers/base'
      autoload :IpRetention, 'vnet/services/ip_retention_containers/base'
    end

    module LeasePolicies
      autoload :Base, 'vnet/services/lease_policies/base'
      autoload :Simple, 'vnet/services/lease_policies/simple'
    end

  end

end

Vnet.logger = ::Logger.new(STDOUT)
