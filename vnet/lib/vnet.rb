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

module Vnet

  ROOT = ENV['VNET_ROOT'] || File.expand_path('../../', __FILE__)
  CONFIG_PATH = ENV['VNET_CONFIG_PATH'] || "/etc/wakame-vnet"
  LOG_DIR = ENV['VNET_LOG_DIR'] || "/var/log/wakame-vnet"

  module Configurations
    autoload :Base,   'vnet/configurations/base'
    autoload :Common, 'vnet/configurations/common'
    autoload :Webapi, 'vnet/configurations/webapi'
    autoload :Vnmgr,  'vnet/configurations/vnmgr'
    autoload :Vna,    'vnet/configurations/vna'
  end

  module Constants
    autoload :Openflow, 'vnet/constants/openflow'
    autoload :OpenflowFlows, 'vnet/constants/openflow_flows'
    autoload :VnetAPI, 'vnet/constants/vnet_api'
  end

  autoload :Event, 'vnet/event'
  module Event
    autoload :Dispatchable, 'vnet/event/dispatchable'
    autoload :Notifications, 'vnet/event/notifications'
  end

  module Endpoints
    autoload :Errors, 'vnet/endpoints/errors'
    autoload :ResponseGenerator, 'vnet/endpoints/response_generator'
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
        autoload :IpAddress, 'vnet/endpoints/1.0/responses/ip_address'
        autoload :IpLease, 'vnet/endpoints/1.0/responses/ip_lease'
        autoload :Interface, 'vnet/endpoints/1.0/responses/interface'
        autoload :LeasePolicy, 'vnet/endpoints/1.0/responses/lease_policy'
        autoload :MacAddress, 'vnet/endpoints/1.0/responses/mac_address'
        autoload :MacLease, 'vnet/endpoints/1.0/responses/mac_lease'
        autoload :Network, 'vnet/endpoints/1.0/responses/network'
        autoload :NetworkService, 'vnet/endpoints/1.0/responses/network_service'
        autoload :Route, 'vnet/endpoints/1.0/responses/route'
        autoload :RouteLink, 'vnet/endpoints/1.0/responses/route_link'
        autoload :SecurityGroup, 'vnet/endpoints/1.0/responses/security_group'
        autoload :Translation, 'vnet/endpoints/1.0/responses/translation'
        autoload :VlanTranslation, 'vnet/endpoints/1.0/responses/vlan_translation'

        autoload :DatapathCollection, 'vnet/endpoints/1.0/responses/datapath'
        autoload :DatapathNetworkCollection, 'vnet/endpoints/1.0/responses/datapath_network'
        autoload :DatapathRouteLinkCollection, 'vnet/endpoints/1.0/responses/datapath_route_link'
        autoload :DnsServiceCollection, 'vnet/endpoints/1.0/responses/dns_service'
        autoload :DnsRecordCollection, 'vnet/endpoints/1.0/responses/dns_record'
        autoload :DhcpRangeCollection, 'vnet/endpoints/1.0/responses/dhcp_range'
        autoload :InterfaceCollection, 'vnet/endpoints/1.0/responses/interface'
        autoload :IpAddressCollection, 'vnet/endpoints/1.0/responses/ip_address'
        autoload :IpLeaseCollection, 'vnet/endpoints/1.0/responses/ip_lease'
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
  end

  module Models
    class InvalidUUIDError < StandardError; end
    autoload :Base, 'vnet/models/base'
    autoload :Datapath, 'vnet/models/datapath'
    autoload :DatapathNetwork, 'vnet/models/datapath_network'
    autoload :DatapathRouteLink, 'vnet/models/datapath_route_link'
    autoload :DcSegment, 'vnet/models/dc_segment'
    autoload :DhcpRange, 'vnet/models/dhcp_range'
    autoload :DnsService, 'vnet/models/dns_service'
    autoload :DnsRecord, 'vnet/models/dns_record'
    autoload :Interface, 'vnet/models/interface'
    autoload :InterfaceSecurityGroup, 'vnet/models/interface_security_group'
    autoload :IpAddress, 'vnet/models/ip_address'
    autoload :IpLease, 'vnet/models/ip_lease'
    autoload :LeasePolicy, 'vnet/models/lease_policy'
    autoload :MacAddress, 'vnet/models/mac_address'
    autoload :MacLease, 'vnet/models/mac_lease'
    autoload :Network, 'vnet/models/network'
    autoload :NetworkService, 'vnet/models/network_service'
    autoload :Route, 'vnet/models/route'
    autoload :RouteLink, 'vnet/models/route_link'
    autoload :SecurityGroup, 'vnet/models/security_group'
    autoload :Taggable, 'vnet/models/base'
    autoload :Translation, 'vnet/models/translation'
    autoload :TranslateStaticAddress, 'vnet/models/translate_static_address'
    autoload :Tunnel, 'vnet/models/tunnel'
    autoload :VlanTranslation, 'vnet/models/vlan_translation'
  end

  module ModelWrappers
    autoload :Base, 'vnet/model_wrappers/base'
    autoload :Datapath, 'vnet/model_wrappers/datapath'
    autoload :DatapathNetwork, 'vnet/model_wrappers/datapath_network'
    autoload :DatapathRouteLink, 'vnet/model_wrappers/datapath_route_link'
    autoload :DcSegment, 'vnet/model_wrappers/dc_segment'
    autoload :DhcpRange, 'vnet/model_wrappers/dhcp_range'
    autoload :DnsService, 'vnet/model_wrappers/dns_service'
    autoload :DnsRecord, 'vnet/model_wrappers/dns_record'
    autoload :Helpers, 'vnet/model_wrappers/helpers'
    autoload :Interface, 'vnet/model_wrappers/interface'
    autoload :InterfaceSecurityGroup, 'vnet/model_wrappers/interface_security_group'
    autoload :IpAddress, 'vnet/model_wrappers/ip_address'
    autoload :IpLease, 'vnet/model_wrappers/ip_lease'
    autoload :LeasePolicy, 'vnet/model_wrappers/lease_policy'
    autoload :MacAddress, 'vnet/model_wrappers/mac_address'
    autoload :MacLease, 'vnet/model_wrappers/mac_lease'
    autoload :Network, 'vnet/model_wrappers/network'
    autoload :NetworkService, 'vnet/model_wrappers/network_service'
    autoload :Route, 'vnet/model_wrappers/route'
    autoload :RouteLink, 'vnet/model_wrappers/route_link'
    autoload :SecurityGroup, 'vnet/model_wrappers/security_group'
    autoload :Translation, 'vnet/model_wrappers/translation'
    autoload :TranslateStaticAddress, 'vnet/model_wrappers/translation'
    autoload :Tunnel, 'vnet/model_wrappers/tunnel'
    autoload :VlanTranslation, 'vnet/model_wrappers/vlan_translation'
  end

  autoload :NodeApi, 'vnet/node_api'
  module NodeApi
    autoload :RpcProxy, 'vnet/node_api/proxies'
    autoload :DirectProxy, 'vnet/node_api/proxies'
    autoload :Base, 'vnet/node_api/base'
    autoload :Datapath, 'vnet/node_api/datapath.rb'
    autoload :DatapathNetwork, 'vnet/node_api/datapath_network.rb'
    autoload :DatapathRouteLink, 'vnet/node_api/models.rb'
    autoload :DcSegment, 'vnet/node_api/models.rb'
    autoload :DhcpRange, 'vnet/node_api/models.rb'
    autoload :DnsService, 'vnet/node_api/dns_service'
    autoload :DnsRecord, 'vnet/node_api/dns_record'
    autoload :Interface, 'vnet/node_api/interface.rb'
    autoload :InterfaceSecurityGroup, 'vnet/node_api/interface_security_group'
    autoload :IpAddress, 'vnet/node_api/models.rb'
    autoload :IpLease, 'vnet/node_api/ip_lease.rb'
    autoload :LeasePolicy, 'vnet/node_api/models.rb'
    autoload :MacAddress, 'vnet/node_api/models.rb'
    autoload :MacLease, 'vnet/node_api/mac_lease.rb'
    autoload :Network, 'vnet/node_api/models.rb'
    autoload :NetworkService, 'vnet/node_api/network_service.rb'
    autoload :Route, 'vnet/node_api/models.rb'
    autoload :RouteLink, 'vnet/node_api/models.rb'
    autoload :SecurityGroup, 'vnet/node_api/security_group'
    autoload :Translation, 'vnet/node_api/models.rb'
    autoload :TranslateStaticAddress, 'vnet/node_api/models.rb'
    autoload :Tunnel, 'vnet/node_api/models.rb'
    autoload :VlanTranslation, 'vnet/node_api/models.rb'
  end

  module NodeModules
    autoload :Rpc, 'vnet/node_modules/rpc'
    autoload :EventHandler, 'vnet/node_modules/event_handler'
    autoload :ServiceOpenflow, 'vnet/node_modules/service_openflow'
    autoload :SwitchManager, 'vnet/node_modules/service_openflow'
  end

  module Openflow
    autoload :AddressHelpers, 'vnet/openflow/address_helpers'
    autoload :ArpLookup, 'vnet/openflow/arp_lookup'
    autoload :ConnectionManager, 'vnet/openflow/connection_manager'
    autoload :Controller, 'vnet/openflow/controller'
    autoload :Datapath, 'vnet/openflow/datapath'
    autoload :DatapathInfo, 'vnet/openflow/datapath'
    autoload :DatapathManager, 'vnet/openflow/datapath_manager'
    autoload :DcSegmentManager, 'vnet/openflow/dc_segment_manager'
    autoload :DpInfo, 'vnet/openflow/dp_info'
    autoload :FilterManager, 'vnet/openflow/filter_manager'
    autoload :Flow, 'vnet/openflow/flow'
    autoload :FlowHelpers, 'vnet/openflow/flow_helpers'
    autoload :Interface, 'vnet/openflow/interface'
    autoload :InterfaceManager, 'vnet/openflow/interface_manager'
    autoload :Manager, 'vnet/openflow/manager'
    autoload :MetadataHelpers, 'vnet/openflow/metadata_helpers'
    autoload :NetworkManager, 'vnet/openflow/network_manager'
    autoload :OvsOfctl, 'vnet/openflow/ovs_ofctl'
    autoload :PacketHelpers, 'vnet/openflow/packet_handler'
    autoload :PortManager, 'vnet/openflow/port_manager'
    autoload :Route, 'vnet/openflow/route'
    autoload :RouteManager, 'vnet/openflow/route_manager'
    autoload :Router, 'vnet/openflow/router'
    autoload :RouterManager, 'vnet/openflow/router_manager'
    autoload :Service, 'vnet/openflow/service'
    autoload :ServiceManager, 'vnet/openflow/service_manager'
    autoload :Switch, 'vnet/openflow/switch'
    autoload :TremaTasks, 'vnet/openflow/trema_tasks'
    autoload :Translation, 'vnet/openflow/translation'
    autoload :TranslationManager, 'vnet/openflow/translation_manager'
    autoload :Tunnel, 'vnet/openflow/tunnel'
    autoload :TunnelManager, 'vnet/openflow/tunnel_manager'

    module Connections
      autoload :Base, 'vnet/openflow/connections/base'
      autoload :TCP, 'vnet/openflow/connections/tcp'
      autoload :UDP, 'vnet/openflow/connections/udp'
    end

    module Datapaths
      autoload :Base, 'vnet/openflow/datapaths/base'
      autoload :Host, 'vnet/openflow/datapaths/host'
      autoload :Remote, 'vnet/openflow/datapaths/remote'
    end

    module Interfaces
      autoload :Base, 'vnet/openflow/interfaces/base'
      autoload :Edge, 'vnet/openflow/interfaces/edge'
      autoload :Host, 'vnet/openflow/interfaces/host'
      autoload :IfBase, 'vnet/openflow/interfaces/if_base'
      autoload :Remote, 'vnet/openflow/interfaces/remote'
      autoload :Simulated, 'vnet/openflow/interfaces/simulated'
      autoload :Vif, 'vnet/openflow/interfaces/vif'
    end

    module Networks
      autoload :Base, 'vnet/openflow/networks/base'
      autoload :Physical, 'vnet/openflow/networks/physical'
      autoload :Virtual, 'vnet/openflow/networks/virtual'
    end

    module Ports
      autoload :Base, 'vnet/openflow/ports/base'
      autoload :Generic, 'vnet/openflow/ports/generic'
      autoload :Host, 'vnet/openflow/ports/host'
      autoload :Local, 'vnet/openflow/ports/local'
      autoload :Tunnel, 'vnet/openflow/ports/tunnel'
      autoload :Vif, 'vnet/openflow/ports/vif'
    end

    module Routes
      autoload :Base, 'vnet/openflow/routes/base'
    end

    module Routers
      autoload :Base, 'vnet/openflow/routers/base'
      autoload :RouteLink, 'vnet/openflow/routers/route_link'
    end

    module Filters
      autoload :AcceptAllTraffic, 'vnet/openflow/filters/accept_all_traffic'
      autoload :AcceptIngressArp, 'vnet/openflow/filters/accept_ingress_arp'
      autoload :Base, 'vnet/openflow/filters/base'
      autoload :Cookies, 'vnet/openflow/filters/cookies'
      autoload :SecurityGroup, 'vnet/openflow/filters/security_group'
    end

    module Services
      autoload :Base, 'vnet/openflow/services/base'
      autoload :Dhcp, 'vnet/openflow/services/dhcp'
      autoload :Dns, 'vnet/openflow/services/dns'
      autoload :Router, 'vnet/openflow/services/router'
    end

    module Translations
      autoload :Base, 'vnet/openflow/translations/base'
      autoload :StaticAddress, 'vnet/openflow/translations/static_address'
      autoload :VnetEdgeHandler, 'vnet/openflow/translations/vnet_edge_handler'
    end

    module Tunnels
      autoload :Base, 'vnet/openflow/tunnels/base'
    end

  end

end
