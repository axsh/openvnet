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
        autoload :DatapathNetwork, 'vnet/endpoints/1.0/responses/datapath_network'
        autoload :DatapathRouteLink, 'vnet/endpoints/1.0/responses/datapath_route_link'
        autoload :DhcpRange, 'vnet/endpoints/1.0/responses/dhcp_range'
        autoload :IpAddress, 'vnet/endpoints/1.0/responses/ip_address'
        autoload :IpLease, 'vnet/endpoints/1.0/responses/ip_lease'
        autoload :MacLease, 'vnet/endpoints/1.0/responses/mac_lease'
        autoload :Network, 'vnet/endpoints/1.0/responses/network'
        autoload :NetworkService, 'vnet/endpoints/1.0/responses/network_service'
        autoload :Route, 'vnet/endpoints/1.0/responses/route'
        autoload :RouteLink, 'vnet/endpoints/1.0/responses/route_link'
        autoload :Vif, 'vnet/endpoints/1.0/responses/vif'

        autoload :DatapathCollection, 'vnet/endpoints/1.0/responses/datapath'
        autoload :DatapathNetworkCollection, 'vnet/endpoints/1.0/responses/datapath_network'
        autoload :DatapathRouteLinkCollection, 'vnet/endpoints/1.0/responses/datapath_route_link'
        autoload :DhcpRangeCollection, 'vnet/endpoints/1.0/responses/dhcp_range'
        autoload :IpAddressCollection, 'vnet/endpoints/1.0/responses/ip_address'
        autoload :IpLeaseCollection, 'vnet/endpoints/1.0/responses/ip_lease'
        autoload :MacLeaseCollection, 'vnet/endpoints/1.0/responses/mac_lease'
        autoload :NetworkCollection, 'vnet/endpoints/1.0/responses/network'
        autoload :NetworkServiceCollection, 'vnet/endpoints/1.0/responses/network_service'
        autoload :RouteCollection, 'vnet/endpoints/1.0/responses/route'
        autoload :RouteLinkCollection, 'vnet/endpoints/1.0/responses/route_link'
        autoload :VifCollection, 'vnet/endpoints/1.0/responses/vif'
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
    autoload :IpAddress, 'vnet/models/ip_address'
    autoload :IpLease, 'vnet/models/ip_lease'
    autoload :MacLease, 'vnet/models/mac_lease'
    autoload :Network, 'vnet/models/network'
    autoload :NetworkService, 'vnet/models/network_service'
    autoload :Route, 'vnet/models/route'
    autoload :RouteLink, 'vnet/models/route_link'
    autoload :Taggable, 'vnet/models/base'
    autoload :Tunnel, 'vnet/models/tunnel'
    autoload :Vif, 'vnet/models/vif'
  end

  module ModelWrappers
    autoload :Base, 'vnet/model_wrappers/base'
    autoload :Datapath, 'vnet/model_wrappers/datapath'
    autoload :DatapathNetwork, 'vnet/model_wrappers/datapath_network'
    autoload :DatapathRouteLink, 'vnet/model_wrappers/datapath_route_link'
    autoload :DcSegment, 'vnet/model_wrappers/dc_segment'
    autoload :DhcpRange, 'vnet/model_wrappers/dhcp_range'
    autoload :Helpers, 'vnet/model_wrappers/helpers'
    autoload :IpAddress, 'vnet/model_wrappers/ip_address'
    autoload :IpLease, 'vnet/model_wrappers/ip_lease'
    autoload :MacLease, 'vnet/model_wrappers/mac_lease'
    autoload :Network, 'vnet/model_wrappers/network'
    autoload :NetworkService, 'vnet/model_wrappers/network_service'
    autoload :Route, 'vnet/model_wrappers/route'
    autoload :RouteLink, 'vnet/model_wrappers/route_link'
    autoload :Tunnel, 'vnet/model_wrappers/tunnel'
    autoload :Vif, 'vnet/model_wrappers/vif'
  end

  autoload :NodeApi, 'vnet/node_api'
  module NodeApi
    autoload :RpcProxy, 'vnet/node_api/proxies'
    autoload :DirectProxy, 'vnet/node_api/proxies'
    autoload :Base, 'vnet/node_api/base'
    autoload :Datapath, 'vnet/node_api/models.rb'
    autoload :DatapathNetwork, 'vnet/node_api/models.rb'
    autoload :DcSegment, 'vnet/node_api/models.rb'
    autoload :DhcpRange, 'vnet/node_api/models.rb'
    autoload :IpAddress, 'vnet/node_api/models.rb'
    autoload :IpLease, 'vnet/node_api/models.rb'
    autoload :MacLease, 'vnet/node_api/models.rb'
    autoload :Network, 'vnet/node_api/models.rb'
    autoload :NetworkService, 'vnet/node_api/models.rb'
    autoload :Route, 'vnet/node_api/models.rb'
    autoload :RouteLink, 'vnet/node_api/models.rb'
    autoload :Tunnel, 'vnet/node_api/models.rb'
    autoload :Vif, 'vnet/node_api/vif.rb'
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
    autoload :InterfaceManager, 'vnet/openflow/interface_manager'
    autoload :NetworkManager, 'vnet/openflow/network_manager'
    autoload :OvsOfctl, 'vnet/openflow/ovs_ofctl'
    autoload :PacketHandler, 'vnet/openflow/packet_handler'
    autoload :PacketManager, 'vnet/openflow/packet_manager'
    autoload :PortManager, 'vnet/openflow/port_manager'
    autoload :RouteManager, 'vnet/openflow/route_manager'
    autoload :Switch, 'vnet/openflow/switch'
    autoload :TremaTasks, 'vnet/openflow/trema_tasks'
    autoload :TunnelManager, 'vnet/openflow/tunnel_manager'

    module Interfaces
      autoload :Base, 'vnet/openflow/interfaces/base'
    end

    module Networks
      autoload :Base, 'vnet/openflow/networks/base'
      autoload :Physical, 'vnet/openflow/networks/physical'
      autoload :Virtual, 'vnet/openflow/networks/virtual'
    end

    module Ports
      autoload :Base, 'vnet/openflow/ports/base'
      autoload :Host, 'vnet/openflow/ports/host'
      autoload :Local, 'vnet/openflow/ports/local'
      autoload :Physical, 'vnet/openflow/ports/physical'
      autoload :Tunnel, 'vnet/openflow/ports/tunnel'
      autoload :Virtual, 'vnet/openflow/ports/virtual'
    end

    module Routers
      autoload :RouteLink, 'vnet/openflow/routers/route_link'
    end

    module Services
      autoload :Arp, 'vnet/openflow/services/arp'
      autoload :ArpLookup, 'vnet/openflow/services/arp_lookup'
      autoload :Base, 'vnet/openflow/services/base'
      autoload :Dhcp, 'vnet/openflow/services/dhcp'
      autoload :Icmp, 'vnet/openflow/services/icmp'
      autoload :Router, 'vnet/openflow/services/router'
    end
  end

end
