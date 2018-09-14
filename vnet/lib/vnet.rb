# -*- coding: utf-8 -*-

#require 'active_support/all'
#require 'active_support/core_ext'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/object'
require 'active_support/json/encoding.rb'
require 'active_support/hash_with_indifferent_access'
require 'active_support/inflector'
require 'ext/kernel'
require 'ext/time'
require 'fuguta'
require 'json'
require 'logger'
require 'ostruct'

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
  autoload :ItemVnetUuid,         'vnet/item_base'
  autoload :ItemVnetUuidMode,     'vnet/item_base'
  autoload :ItemDpBase,           'vnet/item_base'
  autoload :ItemDpUuid,           'vnet/item_base'
  autoload :ItemDpUuidMode,       'vnet/item_base'
  autoload :ItemDatapathUuidMode, 'vnet/item_base'
  autoload :Manager,              'vnet/manager'
  autoload :ManagerAssocs,        'vnet/manager_assocs'
  autoload :LookupParams,         'vnet/manager_params'
  autoload :UpdateItemStates,     'vnet/manager_modules'
  autoload :UpdatePropertyStates, 'vnet/manager_modules'

  autoload :ParamError, 'vnet/manager_params'

  module Configurations
    autoload :Base,   'vnet/configurations/base'
    autoload :Common, 'vnet/configurations/common'
    autoload :Webapi, 'vnet/configurations/webapi'
    autoload :Vnmgr,  'vnet/configurations/vnmgr'
    autoload :Vna,    'vnet/configurations/vna'
  end

  module Constants
    autoload :ActivePort, 'vnet/constants/active_port'
    autoload :Filter, 'vnet/constants/filter'
    autoload :FilterStatic, 'vnet/constants/filter_static'
    autoload :Interface, 'vnet/constants/interface'
    autoload :LeasePolicy, 'vnet/constants/lease_policy'
    autoload :MacAddressPrefix, 'vnet/constants/mac_address_prefix'
    autoload :Network, 'vnet/constants/network'
    autoload :NetworkService, 'vnet/constants/network_service'
    autoload :Openflow, 'vnet/constants/openflow'
    autoload :OpenflowFlows, 'vnet/constants/openflow_flows'
    autoload :Segment, 'vnet/constants/segment'
    autoload :Translation, 'vnet/constants/translation'
    autoload :Topology, 'vnet/constants/topology'
    autoload :VnetAPI, 'vnet/constants/vnet_api'
  end

  module Core
    autoload :Manager, 'vnet/core/manager'
    autoload :ActiveManager, 'vnet/core/active_manager'

    autoload :ActiveInterfaceEvents, 'vnet/core/event_helpers'
    autoload :ActiveNetworkEvents, 'vnet/core/event_helpers'
    autoload :ActivePortEvents, 'vnet/core/event_helpers'
    autoload :ActiveRouteLinkEvents, 'vnet/core/event_helpers'
    autoload :DpInfo, 'vnet/core/dp_info'

    autoload :ActiveInterface, 'vnet/core/items'
    autoload :ActiveInterfaceManager, 'vnet/core/active_interface_manager'
    autoload :ActiveNetwork, 'vnet/core/items'
    autoload :ActiveNetworkManager, 'vnet/core/active_network_manager'
    autoload :ActivePort, 'vnet/core/items'
    autoload :ActivePortManager, 'vnet/core/active_port_manager'
    autoload :ActiveRouteLink, 'vnet/core/items'
    autoload :ActiveRouteLinkManager, 'vnet/core/active_route_link_manager'
    autoload :ActiveSegment, 'vnet/core/items'
    autoload :ActiveSegmentManager, 'vnet/core/active_segment_manager'

    autoload :AddressHelpers, 'vnet/core/address_helpers'
    autoload :Datapath, 'vnet/core/items'
    autoload :DatapathManager, 'vnet/core/datapath_manager'
    autoload :FilterManager, 'vnet/core/filter_manager'
    autoload :Filter, 'vnet/core/items'
    autoload :HostDatapath, 'vnet/core/host_datapath'
    autoload :HostDatapathManager, 'vnet/core/host_datapath_manager'
    autoload :Interface, 'vnet/core/interface'
    autoload :InterfaceManager, 'vnet/core/interface_manager'
    autoload :InterfacePort, 'vnet/core/items'
    autoload :InterfacePortManager, 'vnet/core/interface_port_manager'
    autoload :InterfaceNetwork, 'vnet/core/items'
    autoload :InterfaceNetworkManager, 'vnet/core/interface_network_manager'
    autoload :InterfaceSegment, 'vnet/core/items'
    autoload :InterfaceSegmentManager, 'vnet/core/interface_segment_manager'
    autoload :InterfaceRouteLink, 'vnet/core/items'
    autoload :InterfaceRouteLinkManager, 'vnet/core/interface_route_link_manager'
    autoload :Network, 'vnet/core/items'
    autoload :NetworkManager, 'vnet/core/network_manager'
    autoload :Port, 'vnet/core/port'
    autoload :PortManager, 'vnet/core/port_manager'
    autoload :Route, 'vnet/core/items'
    autoload :RouteManager, 'vnet/core/route_manager'
    autoload :Router, 'vnet/core/items'
    autoload :RouterManager, 'vnet/core/router_manager'
    autoload :Segment, 'vnet/core/items'
    autoload :SegmentManager, 'vnet/core/segment_manager'
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

    module ActivePorts
      autoload :Base, 'vnet/core/active_ports/base'
      autoload :Local, 'vnet/core/active_ports/local'
      autoload :Tunnel, 'vnet/core/active_ports/tunnel'
      autoload :Unknown, 'vnet/core/active_ports/unknown'
    end

    module ActiveRouteLinks
      autoload :Base, 'vnet/core/active_route_links/base'
      autoload :Local, 'vnet/core/active_route_links/local'
      autoload :Remote, 'vnet/core/active_route_links/remote'
    end

    module ActiveSegments
      autoload :Base, 'vnet/core/active_segments/base'
      autoload :Local, 'vnet/core/active_segments/local'
      autoload :Remote, 'vnet/core/active_segments/remote'
    end

    module Datapaths
      autoload :Base, 'vnet/core/datapaths/base'
      autoload :Host, 'vnet/core/datapaths/host'
      autoload :Remote, 'vnet/core/datapaths/remote'
    end

    module Filters
      autoload :Base, 'vnet/core/filters/base'
      autoload :Static, 'vnet/core/filters/static'
    end

    module HostDatapaths
      autoload :Base, 'vnet/core/host_datapaths/base'
    end

    module Interfaces
      autoload :Base, 'vnet/core/interfaces/base'
      autoload :Host, 'vnet/core/interfaces/host'
      autoload :IfBase, 'vnet/core/interfaces/if_base'
      autoload :Internal, 'vnet/core/interfaces/internal'
      autoload :Patch, 'vnet/core/interfaces/patch'
      autoload :Promiscuous, 'vnet/core/interfaces/promiscuous'
      autoload :Simulated, 'vnet/core/interfaces/simulated'
      autoload :Vif, 'vnet/core/interfaces/vif'
    end

    module InterfacePorts
      autoload :Base, 'vnet/core/interface_ports/base'
    end

    module InterfaceNetworks
      autoload :Base, 'vnet/core/interface_networks/base'
    end

    module InterfaceSegments
      autoload :Base, 'vnet/core/interface_segments/base'
    end

    module InterfaceRouteLinks
      autoload :Base, 'vnet/core/interface_route_links/base'
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
      autoload :Promiscuous, 'vnet/core/ports/promiscuous'
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

    module Segments
      autoload :Base, 'vnet/core/segments/base'
      autoload :Virtual, 'vnet/core/segments/virtual'
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
    autoload :IpAddress, 'vnet/helpers/ip_address'
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
        autoload :DatapathSegment, 'vnet/endpoints/1.0/responses/datapath'
        autoload :DatapathRouteLink, 'vnet/endpoints/1.0/responses/datapath_route_link'
        autoload :DnsService, 'vnet/endpoints/1.0/responses/dns_service'
        autoload :DnsRecord, 'vnet/endpoints/1.0/responses/dns_record'
        autoload :Filter, 'vnet/endpoints/1.0/responses/filter'
        autoload :FilterStatic, 'vnet/endpoints/1.0/responses/filter'
        autoload :Interface, 'vnet/endpoints/1.0/responses/interface'
        autoload :InterfacePort, 'vnet/endpoints/1.0/responses/interface_port'
        autoload :InterfaceNetwork, 'vnet/endpoints/1.0/responses/interface'
        autoload :InterfaceSegment, 'vnet/endpoints/1.0/responses/interface'
        autoload :InterfaceRouteLink, 'vnet/endpoints/1.0/responses/interface'
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
        autoload :MacRange, 'vnet/endpoints/1.0/responses/mac_range'
        autoload :MacRangeGroup, 'vnet/endpoints/1.0/responses/mac_range_group'
        autoload :Network, 'vnet/endpoints/1.0/responses/network'
        autoload :NetworkService, 'vnet/endpoints/1.0/responses/network_service'
        autoload :Route, 'vnet/endpoints/1.0/responses/route'
        autoload :RouteLink, 'vnet/endpoints/1.0/responses/route_link'
        autoload :Segment, 'vnet/endpoints/1.0/responses/segment'
        autoload :Topology, 'vnet/endpoints/1.0/responses/topology'
        autoload :TopologyDatapath, 'vnet/endpoints/1.0/responses/topology'
        autoload :TopologyLayer, 'vnet/endpoints/1.0/responses/topology'
        autoload :TopologyMacRangeGroup, 'vnet/endpoints/1.0/responses/topology'
        autoload :TopologyNetwork, 'vnet/endpoints/1.0/responses/topology'
        autoload :TopologySegment, 'vnet/endpoints/1.0/responses/topology'
        autoload :TopologyRouteLink, 'vnet/endpoints/1.0/responses/topology'
        autoload :Translation, 'vnet/endpoints/1.0/responses/translation'
        autoload :TranslationStaticAddress, 'vnet/endpoints/1.0/responses/translation_static_address'

        autoload :DatapathCollection, 'vnet/endpoints/1.0/responses/datapath'
        autoload :DatapathNetworkCollection, 'vnet/endpoints/1.0/responses/datapath_network'
        autoload :DatapathSegmentCollection, 'vnet/endpoints/1.0/responses/datapath'
        autoload :DatapathRouteLinkCollection, 'vnet/endpoints/1.0/responses/datapath_route_link'
        autoload :DnsServiceCollection, 'vnet/endpoints/1.0/responses/dns_service'
        autoload :DnsRecordCollection, 'vnet/endpoints/1.0/responses/dns_record'
        autoload :InterfaceCollection, 'vnet/endpoints/1.0/responses/interface'
        autoload :InterfaceNetworkCollection, 'vnet/endpoints/1.0/responses/interface'
        autoload :InterfaceSegmentCollection, 'vnet/endpoints/1.0/responses/interface'
        autoload :InterfaceRouteLinkCollection, 'vnet/endpoints/1.0/responses/interface'
        autoload :InterfacePortCollection, 'vnet/endpoints/1.0/responses/interface_port'
        autoload :IpAddressCollection, 'vnet/endpoints/1.0/responses/ip_address'
        autoload :IpLeaseCollection, 'vnet/endpoints/1.0/responses/ip_lease'
        autoload :IpLeaseContainerCollection, 'vnet/endpoints/1.0/responses/ip_lease_container'
        autoload :IpRangeCollection, 'vnet/endpoints/1.0/responses/ip_range'
        autoload :IpRangeGroupCollection, 'vnet/endpoints/1.0/responses/ip_range_group'
        autoload :IpRetentionCollection, 'vnet/endpoints/1.0/responses/ip_retention'
        autoload :IpRetentionContainerCollection, 'vnet/endpoints/1.0/responses/ip_retention_container'
        autoload :FilterCollection, 'vnet/endpoints/1.0/responses/filter'
        autoload :FilterStaticCollection, 'vnet/endpoints/1.0/responses/filter'
        autoload :LeasePolicyCollection, 'vnet/endpoints/1.0/responses/lease_policy'
        autoload :MacAddressCollection, 'vnet/endpoints/1.0/responses/mac_address'
        autoload :MacLeaseCollection, 'vnet/endpoints/1.0/responses/mac_lease'
        autoload :MacRangeCollection, 'vnet/endpoints/1.0/responses/mac_range'
        autoload :MacRangeGroupCollection, 'vnet/endpoints/1.0/responses/mac_range_group'
        autoload :NetworkCollection, 'vnet/endpoints/1.0/responses/network'
        autoload :NetworkServiceCollection, 'vnet/endpoints/1.0/responses/network_service'
        autoload :RouteCollection, 'vnet/endpoints/1.0/responses/route'
        autoload :RouteLinkCollection, 'vnet/endpoints/1.0/responses/route_link'
        autoload :SegmentCollection, 'vnet/endpoints/1.0/responses/segment'
        autoload :TopologyCollection, 'vnet/endpoints/1.0/responses/topology'
        autoload :TopologyDatapathCollection, 'vnet/endpoints/1.0/responses/topology'
        autoload :TopologyLayerCollection, 'vnet/endpoints/1.0/responses/topology'
        autoload :TopologyMacRangeGroupCollection, 'vnet/endpoints/1.0/responses/topology'
        autoload :TopologyNetworkCollection, 'vnet/endpoints/1.0/responses/topology'
        autoload :TopologySegmentCollection, 'vnet/endpoints/1.0/responses/topology'
        autoload :TopologyRouteLinkCollection, 'vnet/endpoints/1.0/responses/topology'
        autoload :TranslationCollection, 'vnet/endpoints/1.0/responses/translation'
      end
    end
  end

  module Initializers
    autoload :DB, 'vnet/initializers/db'
    autoload :Logger, 'vnet/initializers/logger'
  end

  module Models
    class InvalidUUIDError < StandardError; end

    autoload :Base, 'vnet/models/base'
    autoload :BaseMode, 'vnet/models/base_mode'
    autoload :BaseTaggable, 'vnet/models/base_taggable'

    autoload :ActiveInterface, 'vnet/models/active_interface'
    autoload :ActiveNetwork, 'vnet/models/active_network'
    autoload :ActivePort, 'vnet/models/active_port'
    autoload :ActiveRouteLink, 'vnet/models/active_route_link'
    autoload :ActiveSegment, 'vnet/models/active_segment'
    autoload :Datapath, 'vnet/models/datapath'
    autoload :DatapathNetwork, 'vnet/models/datapath_network'
    autoload :DatapathSegment, 'vnet/models/datapath_segment'
    autoload :DatapathRouteLink, 'vnet/models/datapath_route_link'
    autoload :DnsService, 'vnet/models/dns_service'
    autoload :DnsRecord, 'vnet/models/dns_record'
    autoload :Interface, 'vnet/models/interface'
    autoload :InterfacePort, 'vnet/models/interface_port'
    autoload :InterfaceNetwork, 'vnet/models/interface_network'
    autoload :InterfaceSegment, 'vnet/models/interface_segment'
    autoload :InterfaceRouteLink, 'vnet/models/interface_route_link'
    autoload :IpAddress, 'vnet/models/ip_address'
    autoload :IpLease, 'vnet/models/ip_lease'
    autoload :IpLeaseContainer, 'vnet/models/ip_lease_container'
    autoload :IpLeaseContainerIpLease, 'vnet/models/ip_lease_container_ip_lease'
    autoload :IpRange, 'vnet/models/ip_range'
    autoload :IpRangeGroup, 'vnet/models/ip_range_group'
    autoload :IpRetention, 'vnet/models/ip_retention'
    autoload :IpRetentionContainer, 'vnet/models/ip_retention_container'
    autoload :Filter, 'vnet/models/filter'
    autoload :FilterStatic, 'vnet/models/filter_static'
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
    autoload :Segment, 'vnet/models/segment'
    autoload :Taggable, 'vnet/models/base'
    autoload :Topology, 'vnet/models/topology'
    autoload :TopologyDatapath, 'vnet/models/topology_datapath'
    autoload :TopologyLayer, 'vnet/models/topology_layer'
    autoload :TopologyMacRangeGroup, 'vnet/models/topology_mac_range_group'
    autoload :TopologyNetwork, 'vnet/models/topology_network'
    autoload :TopologySegment, 'vnet/models/topology_segment'
    autoload :TopologyRouteLink, 'vnet/models/topology_route_link'
    autoload :Translation, 'vnet/models/translation'
    autoload :TranslationStaticAddress, 'vnet/models/translation_static_address'
    autoload :Tunnel, 'vnet/models/tunnel'
  end

  module ModelWrappers
    autoload :ActiveInterface, 'vnet/model_wrappers/wrappers'
    autoload :ActiveNetwork, 'vnet/model_wrappers/wrappers'
    autoload :ActivePort, 'vnet/model_wrappers/active_port'
    autoload :ActiveRouteLink, 'vnet/model_wrappers/wrappers'
    autoload :ActiveSegment, 'vnet/model_wrappers/wrappers'
    autoload :Base, 'vnet/model_wrappers/base'
    autoload :Datapath, 'vnet/model_wrappers/datapath'
    autoload :DatapathNetwork, 'vnet/model_wrappers/datapath'
    autoload :DatapathSegment, 'vnet/model_wrappers/datapath'
    autoload :DatapathRouteLink, 'vnet/model_wrappers/datapath'
    autoload :DnsService, 'vnet/model_wrappers/dns_service'
    autoload :DnsRecord, 'vnet/model_wrappers/dns_record'
    autoload :Helpers, 'vnet/model_wrappers/helpers'
    autoload :Interface, 'vnet/model_wrappers/interface'
    autoload :InterfacePort, 'vnet/model_wrappers/interface'
    autoload :InterfaceNetwork, 'vnet/model_wrappers/interface'
    autoload :InterfaceSegment, 'vnet/model_wrappers/interface'
    autoload :InterfaceRouteLink, 'vnet/model_wrappers/interface'
    autoload :IpAddress, 'vnet/model_wrappers/ip_address'
    autoload :IpLease, 'vnet/model_wrappers/ip_lease'
    autoload :IpLeaseContainer, 'vnet/model_wrappers/ip_lease_container'
    autoload :IpLeaseContainerIpLease, 'vnet/model_wrappers/ip_lease_container_ip_lease'
    autoload :IpRange, 'vnet/model_wrappers/wrappers'
    autoload :IpRangeGroup, 'vnet/model_wrappers/wrappers'
    autoload :IpRetention, 'vnet/model_wrappers/ip_retention'
    autoload :IpRetentionContainer, 'vnet/model_wrappers/ip_retention_container'
    autoload :Filter, 'vnet/model_wrappers/filter'
    autoload :FilterStatic, 'vnet/model_wrappers/filter'
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
    autoload :Segment, 'vnet/model_wrappers/wrappers'
    autoload :Topology, 'vnet/model_wrappers/topology'
    autoload :TopologyDatapath, 'vnet/model_wrappers/topology'
    autoload :TopologyLayer, 'vnet/model_wrappers/topology'
    autoload :TopologyMacRangeGroup, 'vnet/model_wrappers/topology'
    autoload :TopologyNetwork, 'vnet/model_wrappers/topology'
    autoload :TopologySegment, 'vnet/model_wrappers/topology'
    autoload :TopologyRouteLink, 'vnet/model_wrappers/topology'
    autoload :Translation, 'vnet/model_wrappers/translation'
    autoload :TranslationStaticAddress, 'vnet/model_wrappers/translation'
    autoload :Tunnel, 'vnet/model_wrappers/tunnel'
  end

  autoload :NodeApi, 'vnet/node_api'

  module NodeApi
    autoload :RpcProxy, 'vnet/node_api/proxies'
    autoload :DirectProxy, 'vnet/node_api/proxies'

    autoload :Base, 'vnet/node_api/base'
    autoload :BaseValidateUpdateFields, 'vnet/node_api/base_valid_update_fields'
    autoload :AssocBase, 'vnet/node_api/assoc_base'
    autoload :EventBase, 'vnet/node_api/event_base'
    autoload :LegacyBase, 'vnet/node_api/models'

    autoload :ActiveInterface, 'vnet/node_api/active_interface'
    autoload :ActiveNetwork, 'vnet/node_api/active_network'
    autoload :ActivePort, 'vnet/node_api/active_port'
    autoload :ActiveRouteLink, 'vnet/node_api/active_route_link'
    autoload :ActiveSegment, 'vnet/node_api/active_segment'
    autoload :Datapath, 'vnet/node_api/datapath'
    autoload :DatapathGeneric, 'vnet/node_api/datapath_generic'
    autoload :DatapathNetwork, 'vnet/node_api/datapath_generic'
    autoload :DatapathSegment, 'vnet/node_api/datapath_generic'
    autoload :DatapathRouteLink, 'vnet/node_api/datapath_generic'
    autoload :DnsService, 'vnet/node_api/dns_service'
    autoload :DnsRecord, 'vnet/node_api/dns_record'
    autoload :Interface, 'vnet/node_api/interface'
    autoload :InterfacePort, 'vnet/node_api/interface_port'
    autoload :InterfaceNetwork, 'vnet/node_api/interface_assoc'
    autoload :InterfaceSegment, 'vnet/node_api/interface_assoc'
    autoload :InterfaceRouteLink, 'vnet/node_api/interface_assoc'
    autoload :IpAddress, 'vnet/node_api/models'
    autoload :IpLease, 'vnet/node_api/ip_lease'
    autoload :IpLeaseContainer, 'vnet/node_api/ip_lease_container'
    autoload :IpRange, 'vnet/node_api/models'
    autoload :IpRangeGroup, 'vnet/node_api/models'
    autoload :IpRetention, 'vnet/node_api/ip_retention'
    autoload :Filter, 'vnet/node_api/filter'
    autoload :FilterStatic, 'vnet/node_api/filter_static'
    autoload :IpRetentionContainer, 'vnet/node_api/ip_retention_container'
    autoload :LeasePolicy, 'vnet/node_api/lease_policy'
    autoload :LeasePolicyBaseInterface, 'vnet/node_api/models'
    autoload :LeasePolicyBaseNetwork, 'vnet/node_api/models'
    autoload :MacAddress, 'vnet/node_api/models'
    autoload :MacLease, 'vnet/node_api/mac_lease'
    autoload :MacRange, 'vnet/node_api/mac_range'
    autoload :MacRangeGroup, 'vnet/node_api/mac_range'
    autoload :Network, 'vnet/node_api/network'
    autoload :NetworkService, 'vnet/node_api/network_service'
    autoload :Route, 'vnet/node_api/route'
    autoload :RouteLink, 'vnet/node_api/route_link'
    autoload :Segment, 'vnet/node_api/segment'
    autoload :Topology, 'vnet/node_api/topology'
    autoload :TopologyAssocBase, 'vnet/node_api/topology'
    autoload :TopologyDatapath, 'vnet/node_api/topology'
    autoload :TopologyLayer, 'vnet/node_api/topology'
    autoload :TopologyMacRangeGroup, 'vnet/node_api/topology'
    autoload :TopologyNetwork, 'vnet/node_api/topology'
    autoload :TopologySegment, 'vnet/node_api/topology'
    autoload :TopologyRouteLink, 'vnet/node_api/topology'
    autoload :Translation, 'vnet/node_api/translation'
    autoload :TranslationStaticAddress, 'vnet/node_api/translation_static_address'
    autoload :Tunnel, 'vnet/node_api/tunnel'
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

  module Services
    autoload :IpRetentionContainerManager, 'vnet/services/ip_retention_container_manager'
    autoload :LeasePolicy, 'vnet/services/lease_policy'
    autoload :LeasePolicyManager, 'vnet/services/lease_policy_manager'
    autoload :Manager, 'vnet/services/manager'
    autoload :Topology, 'vnet/services/items'
    autoload :TopologyManager, 'vnet/services/topology_manager'
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

    module Topologies
      autoload :Base, 'vnet/services/topologies/base'
      autoload :SimpleOverlay, 'vnet/services/topologies/simple_overlay'
      autoload :SimpleUnderlay, 'vnet/services/topologies/simple_underlay'
    end

  end

end

Vnet.logger = ::Logger.new(STDOUT)
