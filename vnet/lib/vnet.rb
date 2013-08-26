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
    autoload :Base,  'vnet/configurations/base'
    autoload :Common,  'vnet/configurations/common'
    autoload :Webapi,  'vnet/configurations/webapi'
    autoload :Vnmgr,  'vnet/configurations/vnmgr'
    autoload :Vna,  'vnet/configurations/vna'
  end

  module Constants
    autoload :Openflow, 'vnet/constants/openflow'
    autoload :OpenflowFlows, 'vnet/constants/openflow_flows'
    autoload :VnetAPI, 'vnet/constants/vnet_api'
  end

  module Event
    autoload :Dispatchable, 'vnet/event/dispatchable'
  end

  module Endpoints
    autoload :Errors, 'vnet/endpoints/errors'
    autoload :ResponseGenerator, 'vnet/endpoints/response_generator'
    module V10
      autoload :Helpers, 'vnet/endpoints/1.0/helpers'
      autoload :VnetAPI, 'vnet/endpoints/1.0/vnet_api'
      module Responses
        autoload :Datapath, 'vnet/endpoints/1.0/responses/datapath'
        autoload :DcNetwork, 'vnet/endpoints/1.0/responses/dc_network'
        autoload :DhcpRange, 'vnet/endpoints/1.0/responses/dhcp_range'
        autoload :IpAddress, 'vnet/endpoints/1.0/responses/ip_address'
        autoload :IpLease, 'vnet/endpoints/1.0/responses/ip_lease'
        autoload :Interface, 'vnet/endpoints/1.0/responses/interface'
        autoload :MacAddress, 'vnet/endpoints/1.0/responses/mac_address'
        autoload :MacLease, 'vnet/endpoints/1.0/responses/mac_lease'
        autoload :MacRange, 'vnet/endpoints/1.0/responses/mac_range'
        autoload :Network, 'vnet/endpoints/1.0/responses/network'
        autoload :NetworkService, 'vnet/endpoints/1.0/responses/network_service'
        autoload :OpenFlowController, 'vnet/endpoints/1.0/responses/open_flow_controller'
        autoload :Route, 'vnet/endpoints/1.0/responses/route'
        autoload :RouteLink, 'vnet/endpoints/1.0/responses/route_link'

        autoload :DatapathCollection, 'vnet/endpoints/1.0/responses/datapath'
        autoload :DcNetworkCollection, 'vnet/endpoints/1.0/responses/dc_network'
        autoload :DhcpRangeCollection, 'vnet/endpoints/1.0/responses/dhcp_range'
        autoload :InterfaceCollection, 'vnet/endpoints/1.0/responses/interface'
        autoload :IpAddressCollection, 'vnet/endpoints/1.0/responses/ip_address'
        autoload :IpLeaseCollection, 'vnet/endpoints/1.0/responses/ip_lease'
        autoload :MacAddressCollection, 'vnet/endpoints/1.0/responses/mac_address'
        autoload :MacLeaseCollection, 'vnet/endpoints/1.0/responses/mac_lease'
        autoload :MacRangeCollection, 'vnet/endpoints/1.0/responses/mac_range'
        autoload :NetworkCollection, 'vnet/endpoints/1.0/responses/network'
        autoload :NetworkServiceCollection, 'vnet/endpoints/1.0/responses/network_service'
        autoload :OpenFlowControllerCollection, 'vnet/endpoints/1.0/responses/open_flow_controller'
        autoload :RouteCollection, 'vnet/endpoints/1.0/responses/route'
        autoload :RouteLinkCollection, 'vnet/endpoints/1.0/responses/route_link'
      end
    end
  end

  module Initializers
    autoload :DB, 'vnet/initializers/db'
  end

  module Models
    autoload :Base, 'vnet/models/base'
    autoload :Datapath, 'vnet/models/datapath'
    autoload :DatapathNetwork, 'vnet/models/datapath_network'
    autoload :DatapathRouteLink, 'vnet/models/datapath_route_link'
    autoload :DcNetwork, 'vnet/models/dc_network'
    autoload :DcNetworkDcSegment, 'vnet/models/dc_network_dc_segment'
    autoload :DcSegment, 'vnet/models/dc_segment'
    autoload :DhcpRange, 'vnet/models/dhcp_range'
    autoload :Interface, 'vnet/models/interface'
    autoload :IpAddress, 'vnet/models/ip_address'
    autoload :IpLease, 'vnet/models/ip_lease'
    autoload :MacAddress, 'vnet/models/mac_address'
    autoload :MacLease, 'vnet/models/mac_lease'
    autoload :MacRange, 'vnet/models/mac_range'
    autoload :Network, 'vnet/models/network'
    autoload :NetworkService, 'vnet/models/network_service'
    autoload :OpenFlowController, 'vnet/models/open_flow_controller'
    autoload :Route, 'vnet/models/route'
    autoload :RouteLink, 'vnet/models/route_link'
    autoload :Taggable, 'vnet/models/base'
    autoload :Tunnel, 'vnet/models/tunnel'
  end

  module ModelWrappers
    autoload :Base, 'vnet/model_wrappers/base'
    autoload :Datapath, 'vnet/model_wrappers/datapath'
    autoload :DatapathNetwork, 'vnet/model_wrappers/datapath_network'
    autoload :DatapathRouteLink, 'vnet/model_wrappers/datapath_route_link'
    autoload :DcNetwork, 'vnet/model_wrappers/dc_network'
    autoload :DcNetworkDcSegment, 'vnet/model_wrappers/dc_network_dc_segment'
    autoload :DcSegment, 'vnet/model_wrappers/dc_segment'
    autoload :DhcpRange, 'vnet/model_wrappers/dhcp_range'
    autoload :Interface, 'vnet/model_wrappers/interface'
    autoload :IpAddress, 'vnet/model_wrappers/ip_address'
    autoload :IpLease, 'vnet/model_wrappers/ip_lease'
    autoload :MacAddress, 'vnet/model_wrappers/mac_address'
    autoload :MacLease, 'vnet/model_wrappers/mac_lease'
    autoload :MacRange, 'vnet/model_wrappers/mac_range'
    autoload :Network, 'vnet/model_wrappers/network'
    autoload :NetworkService, 'vnet/model_wrappers/network_service'
    autoload :OpenFlowController, 'vnet/model_wrappers/open_flow_controller'
    autoload :Route, 'vnet/model_wrappers/route'
    autoload :RouteLink, 'vnet/model_wrappers/route_link'
    autoload :Tunnel, 'vnet/model_wrappers/tunnel'
  end

  autoload :NodeApi, 'vnet/node_api'
  module NodeApi
    autoload :RpcProxy, 'vnet/node_api/proxies'
    autoload :DirectProxy, 'vnet/node_api/proxies'
    autoload :Base, 'vnet/node_api/base'
    autoload :Datapath, 'vnet/node_api/models.rb'
    autoload :DatapathNetwork, 'vnet/node_api/models.rb'
    autoload :DcNetwork, 'vnet/node_api/models.rb'
    autoload :DcNetworkDcSegment, 'vnet/node_api/models.rb'
    autoload :DcSegment, 'vnet/node_api/models.rb'
    autoload :DhcpRange, 'vnet/node_api/models.rb'
    autoload :Interface, 'vnet/node_api/interface.rb'
    autoload :IpAddress, 'vnet/node_api/models.rb'
    autoload :IpLease, 'vnet/node_api/models.rb'
    autoload :MacAddress, 'vnet/node_api/models.rb'
    autoload :MacRange, 'vnet/node_api/models.rb'
    autoload :Network, 'vnet/node_api/models.rb'
    autoload :NetworkService, 'vnet/node_api/models.rb'
    autoload :OpenFlowController, 'vnet/node_api/models.rb'
    autoload :Route, 'vnet/node_api/models.rb'
    autoload :RouteLink, 'vnet/node_api/models.rb'
    autoload :Tunnel, 'vnet/node_api/models.rb'
  end

  module NodeModules
    autoload :Rpc, 'vnet/node_modules/rpc'
    autoload :EventHandler, 'vnet/node_modules/event_handler'
    autoload :ServiceOpenflow, 'vnet/node_modules/service_openflow'
  end

  module Openflow
    autoload :CookieCategory, 'vnet/openflow/cookie_manager'
    autoload :CookieManager, 'vnet/openflow/cookie_manager'
    autoload :Controller, 'vnet/openflow/controller'
    autoload :Datapath, 'vnet/openflow/datapath'
    autoload :DcSegmentManager, 'vnet/openflow/dc_segment_manager'
    autoload :Flow, 'vnet/openflow/flow'
    autoload :FlowHelpers, 'vnet/openflow/flow'
    autoload :Network, 'vnet/openflow/network'
    autoload :NetworkPhysical, 'vnet/openflow/network_physical'
    autoload :NetworkVirtual, 'vnet/openflow/network_virtual'
    autoload :NetworkManager, 'vnet/openflow/network_manager'
    autoload :OvsOfctl, 'vnet/openflow/ovs_ofctl'
    autoload :PacketHandler, 'vnet/openflow/packet_handler'
    autoload :PacketManager, 'vnet/openflow/packet_manager'
    autoload :Port, 'vnet/openflow/port'
    autoload :PortTunnel, 'vnet/openflow/port_tunnel'
    autoload :PortHost, 'vnet/openflow/port_host'
    autoload :PortLocal, 'vnet/openflow/port_local'
    autoload :PortPhysical, 'vnet/openflow/port_physical'
    autoload :PortVirtual, 'vnet/openflow/port_virtual'
    autoload :RouteManager, 'vnet/openflow/route_manager'
    autoload :Switch, 'vnet/openflow/switch'
    autoload :TremaTasks, 'vnet/openflow/trema_tasks'
    autoload :TunnelManager, 'vnet/openflow/tunnel_manager'

    module Routers
      autoload :RouteLink, 'vnet/openflow/routers/route_link'
    end

    module Services
      autoload :Arp, 'vnet/openflow/services/arp'
      autoload :Base, 'vnet/openflow/services/base'
      autoload :Dhcp, 'vnet/openflow/services/dhcp'
      autoload :Icmp, 'vnet/openflow/services/icmp'
      autoload :Router, 'vnet/openflow/services/router'
    end
  end

end
