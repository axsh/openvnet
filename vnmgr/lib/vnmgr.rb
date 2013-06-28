# -*- coding: utf-8 -*-

#require 'active_support/all'
#require 'active_support/core_ext'
require 'active_support/core_ext/class'
require 'active_support/core_ext/object'
require 'active_support/hash_with_indifferent_access'
require 'active_support/inflector'
require 'ext/kernel'
require 'fuguta'
require 'json'

module Vnmgr

  ROOT = ENV['VNMGR_ROOT'] || File.expand_path('../../', __FILE__)
  CONFIG_PATH = ENV['VNMGR_CONFIG_PATH'] || "/etc/wakame-vnet"
  LOG_DIR = ENV['VNMGR_LOG_DIR'] || "/var/log/wakame-vnet"

  module Configurations
    autoload :Base,  'vnmgr/configurations/base'
    autoload :Common,  'vnmgr/configurations/common'
    autoload :Dba,  'vnmgr/configurations/dba'
    autoload :Vnmgr,  'vnmgr/configurations/vnmgr'
    autoload :Vna,  'vnmgr/configurations/vna'
  end

  module Constants
    autoload :VNetAPI, 'vnmgr/constants/vnet_api'
  end

  autoload :DataAccess, 'vnmgr/data_access'
  module DataAccess
    autoload :DbaProxy, 'vnmgr/data_access/proxies'
    autoload :DirectProxy, 'vnmgr/data_access/proxies'
    module Models
      autoload :Base, 'vnmgr/data_access/models/base'
      autoload :Datapath, 'vnmgr/data_access/models/models.rb'
      autoload :DatapathNetwork, 'vnmgr/data_access/models/models.rb'
      autoload :DcNetwork, 'vnmgr/data_access/models/models.rb'
      autoload :DcNetworkDcSegment, 'vnmgr/data_access/models/models.rb'
      autoload :DcSegment, 'vnmgr/data_access/models/models.rb'
      autoload :DhcpRange, 'vnmgr/data_access/models/models.rb'
      autoload :IpAddress, 'vnmgr/data_access/models/models.rb'
      autoload :IpLease, 'vnmgr/data_access/models/models.rb'
      autoload :MacRange, 'vnmgr/data_access/models/models.rb'
      autoload :Network, 'vnmgr/data_access/models/models.rb'
      autoload :NetworkService, 'vnmgr/data_access/models/models.rb'
      autoload :OpenFlowController, 'vnmgr/data_access/models/models.rb'
      autoload :Route, 'vnmgr/data_access/models/models.rb'
      autoload :RouteLink, 'vnmgr/data_access/models/models.rb'
      autoload :Tunnel, 'vnmgr/data_access/models/models.rb'
      autoload :Vif, 'vnmgr/data_access/models/models.rb'
    end
  end

  module Endpoints
    autoload :Errors, 'vnmgr/endpoints/errors'
    autoload :ResponseGenerator, 'vnmgr/endpoints/response_generator'
    module V10
      autoload :Helpers, 'vnmgr/endpoints/1.0/helpers'
      autoload :VNetAPI, 'vnmgr/endpoints/1.0/vnet_api'
      module Responses
        autoload :Datapath, 'vnmgr/endpoints/1.0/responses/datapath'
        autoload :DcNetwork, 'vnmgr/endpoints/1.0/responses/dc_network'
        autoload :DhcpRange, 'vnmgr/endpoints/1.0/responses/dhcp_range'
        autoload :IpAddress, 'vnmgr/endpoints/1.0/responses/ip_address'
        autoload :IpLease, 'vnmgr/endpoints/1.0/responses/ip_lease'
        autoload :MacLease, 'vnmgr/endpoints/1.0/responses/mac_lease'
        autoload :MacRange, 'vnmgr/endpoints/1.0/responses/mac_range'
        autoload :Network, 'vnmgr/endpoints/1.0/responses/network'
        autoload :NetworkService, 'vnmgr/endpoints/1.0/responses/network_service'
        autoload :OpenFlowController, 'vnmgr/endpoints/1.0/responses/open_flow_controller'
        autoload :Route, 'vnmgr/endpoints/1.0/responses/route'
        autoload :RouteLink, 'vnmgr/endpoints/1.0/responses/route_link'
        autoload :Tunnel, 'vnmgr/endpoints/1.0/responses/tunnel'
        autoload :Vif, 'vnmgr/endpoints/1.0/responses/vif'

        autoload :DatapathCollection, 'vnmgr/endpoints/1.0/responses/datapath'
        autoload :DcNetworkCollection, 'vnmgr/endpoints/1.0/responses/dc_network'
        autoload :DhcpRangeCollection, 'vnmgr/endpoints/1.0/responses/dhcp_range'
        autoload :IpAddressCollection, 'vnmgr/endpoints/1.0/responses/ip_address'
        autoload :IpLeaseCollection, 'vnmgr/endpoints/1.0/responses/ip_lease'
        autoload :MacLeaseCollection, 'vnmgr/endpoints/1.0/responses/mac_lease'
        autoload :MacRangeCollection, 'vnmgr/endpoints/1.0/responses/mac_range'
        autoload :NetworkCollection, 'vnmgr/endpoints/1.0/responses/network'
        autoload :NetworkServiceCollection, 'vnmgr/endpoints/1.0/responses/network_service'
        autoload :OpenFlowControllerCollection, 'vnmgr/endpoints/1.0/responses/open_flow_controller'
        autoload :RouteCollection, 'vnmgr/endpoints/1.0/responses/route'
        autoload :RouteLinkCollection, 'vnmgr/endpoints/1.0/responses/route_link'
        autoload :TunnelCollection, 'vnmgr/endpoints/1.0/responses/tunnel'
        autoload :VifCollection, 'vnmgr/endpoints/1.0/responses/vif'
      end
    end
  end

  module Initializers
    autoload :DB, 'vnmgr/initializers/db'
  end

  module Models
    autoload :Base, 'vnmgr/models/base'
    autoload :Datapath, 'vnmgr/models/datapath'
    autoload :DatapathNetwork, 'vnmgr/models/datapath_network'
    autoload :DcNetwork, 'vnmgr/models/dc_network'
    autoload :DcNetworkDcSegment, 'vnmgr/models/dc_network_dc_segment'
    autoload :DcSegment, 'vnmgr/models/dc_segment'
    autoload :DhcpRange, 'vnmgr/models/dhcp_range'
    autoload :IpAddress, 'vnmgr/models/ip_address'
    autoload :IpLease, 'vnmgr/models/ip_lease'
    autoload :MacRange, 'vnmgr/models/mac_range'
    autoload :Network, 'vnmgr/models/network'
    autoload :NetworkService, 'vnmgr/models/network_service'
    autoload :OpenFlowController, 'vnmgr/models/open_flow_controller'
    autoload :Route, 'vnmgr/models/route'
    autoload :RouteLink, 'vnmgr/models/route_link'
    autoload :Taggable, 'vnmgr/models/base'
    autoload :Tunnel, 'vnmgr/models/tunnel'
    autoload :Vif, 'vnmgr/models/vif'
  end

  module ModelWrappers
    autoload :Base, 'vnmgr/model_wrappers/base'
    autoload :Datapath, 'vnmgr/model_wrappers/datapath'
    autoload :DatapathNetwork, 'vnmgr/model_wrappers/datapath_network'
    autoload :DcNetwork, 'vnmgr/model_wrappers/dc_network'
    autoload :DcNetworkDcSegment, 'vnmgr/model_wrappers/dc_network_dc_segment'
    autoload :DcSegment, 'vnmgr/model_wrappers/dc_segment'
    autoload :DhcpRange, 'vnmgr/model_wrappers/dhcp_range'
    autoload :IpAddress, 'vnmgr/model_wrappers/ip_address'
    autoload :IpLease, 'vnmgr/model_wrappers/ip_lease'
    autoload :MacRange, 'vnmgr/model_wrappers/mac_range'
    autoload :Network, 'vnmgr/model_wrappers/network'
    autoload :NetworkService, 'vnmgr/model_wrappers/network_service'
    autoload :OpenFlowController, 'vnmgr/model_wrappers/open_flow_controller'
    autoload :Route, 'vnmgr/model_wrappers/route'
    autoload :RouteLink, 'vnmgr/model_wrappers/route_link'
    autoload :Tunnel, 'vnmgr/model_wrappers/tunnel'
    autoload :Vif, 'vnmgr/model_wrappers/vif'
  end

  module NodeModules
    autoload :Dba, 'vnmgr/node_modules/dba'
    autoload :ServiceOpenflow, 'vnmgr/node_modules/service_openflow'
  end

  module VNet
    module Openflow
      autoload :CookieManager, 'vnmgr/vnet/openflow/cookie_manager'
      autoload :Constants, 'vnmgr/vnet/openflow/constants'
      autoload :Controller, 'vnmgr/vnet/openflow/controller'
      autoload :Datapath, 'vnmgr/vnet/openflow/datapath'
      autoload :DcSegmentManager, 'vnmgr/vnet/openflow/dc_segment_manager'
      autoload :Flow, 'vnmgr/vnet/openflow/flow'
      autoload :Network, 'vnmgr/vnet/openflow/network'
      autoload :NetworkPhysical, 'vnmgr/vnet/openflow/network_physical'
      autoload :NetworkVirtual, 'vnmgr/vnet/openflow/network_virtual'
      autoload :NetworkManager, 'vnmgr/vnet/openflow/network_manager'
      autoload :OvsOfctl, 'vnmgr/vnet/openflow/ovs_ofctl'
      autoload :PacketHandler, 'vnmgr/vnet/openflow/packet_handler'
      autoload :PacketManager, 'vnmgr/vnet/openflow/packet_manager'
      autoload :Port, 'vnmgr/vnet/openflow/port'
      autoload :PortGre, 'vnmgr/vnet/openflow/port_gre'
      autoload :PortHost, 'vnmgr/vnet/openflow/port_host'
      autoload :PortLocal, 'vnmgr/vnet/openflow/port_local'
      autoload :PortPhysical, 'vnmgr/vnet/openflow/port_physical'
      autoload :PortVirtual, 'vnmgr/vnet/openflow/port_virtual'
      autoload :Switch, 'vnmgr/vnet/openflow/switch'
      autoload :TremaTasks, 'vnmgr/vnet/openflow/trema_tasks'
      autoload :TunnelManager, 'vnmgr/vnet/openflow/tunnel_manager'
    end

    module Services
      autoload :Arp, 'vnmgr/vnet/services/arp'
      autoload :Dhcp, 'vnmgr/vnet/services/dhcp'
      autoload :Icmp, 'vnmgr/vnet/services/icmp'
      autoload :Router, 'vnmgr/vnet/services/router'
    end

  end

end
