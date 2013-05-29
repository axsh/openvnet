# -*- coding: utf-8 -*-

require 'ext/kernel'

module Vnmgr

  VNMGR_ROOT = ENV['VNMGR_ROOT'] || File.expand_path('../../', __FILE__)

  module Initializers
    autoload :DB, 'vnmgr/initializers/db'
  end

  module Constants
    module StorageBackends
      autoload :DBA, 'vnmgr/constants/storage_backends/dba'
    end
    autoload :VNetAPI, 'vnmgr/constants/vnet_api'
  end

  module Endpoints
    autoload :ResponseGenerator, 'vnmgr/endpoints/response_generator'
    autoload :Errors, 'vnmgr/endpoints/errors'
    module V10
      autoload :VNetAPI, 'vnmgr/endpoints/1.0/vnet_api'
      autoload :Helpers, 'vnmgr/endpoints/1.0/helpers'

      module Responses
        autoload :Network, 'vnmgr/endpoints/1.0/responses/network'
        autoload :Vif, 'vnmgr/endpoints/1.0/responses/vif'
        autoload :DhcpRange, 'vnmgr/endpoints/1.0/responses/dhcp_range'
        autoload :MacRange, 'vnmgr/endpoints/1.0/responses/mac_range'
        autoload :MacLease, 'vnmgr/endpoints/1.0/responses/mac_lease'
        autoload :Router, 'vnmgr/endpoints/1.0/responses/router'
        autoload :Tunnel, 'vnmgr/endpoints/1.0/responses/tunnel'
        autoload :DcNetwork, 'vnmgr/endpoints/1.0/responses/dc_network'
        autoload :Datapath, 'vnmgr/endpoints/1.0/responses/datapath'
        autoload :OpenFlowController, 'vnmgr/endpoints/1.0/responses/open_flow_controller'
        autoload :IpAddress, 'vnmgr/endpoints/1.0/responses/ip_address'
        autoload :IpLease, 'vnmgr/endpoints/1.0/responses/ip_lease'
        autoload :NetworkService, 'vnmgr/endpoints/1.0/responses/network_service'

        autoload :NetworkCollection, 'vnmgr/endpoints/1.0/responses/network'
        autoload :VifCollection, 'vnmgr/endpoints/1.0/responses/vif'
        autoload :DhcpRangeCollection, 'vnmgr/endpoints/1.0/responses/dhcp_range'
        autoload :MacRangeCollection, 'vnmgr/endpoints/1.0/responses/mac_range'
        autoload :MacLeaseCollection, 'vnmgr/endpoints/1.0/responses/mac_lease'
        autoload :RouterCollection, 'vnmgr/endpoints/1.0/responses/router'
        autoload :TunnelCollection, 'vnmgr/endpoints/1.0/responses/tunnel'
        autoload :DcNetworkCollection, 'vnmgr/endpoints/1.0/responses/dc_network'
        autoload :DatapathCollection, 'vnmgr/endpoints/1.0/responses/datapath'
        autoload :OpenFlowControllerCollection, 'vnmgr/endpoints/1.0/responses/open_flow_controller'
        autoload :IpAddressCollection, 'vnmgr/endpoints/1.0/responses/ip_address'
        autoload :IpLeaseCollection, 'vnmgr/endpoints/1.0/responses/ip_lease'
        autoload :NetworkServiceCollection, 'vnmgr/endpoints/1.0/responses/network_service'
      end
    end
  end

  module NodeModules
    autoload :Dba,	'vnmgr/node_modules/dba'
    module DBA
      autoload :Base, 'vnmgr/node_modules/dba/base'
      autoload :Network, 'vnmgr/node_modules/dba/network'
      autoload :Vif, 'vnmgr/node_modules/dba/vif'
      autoload :DhcpRange, 'vnmgr/node_modules/dba/dhcp_range'
      autoload :MacRange, 'vnmgr/node_modules/dba/mac_range'
      autoload :Router, 'vnmgr/node_modules/dba/router'
      autoload :Tunnel, 'vnmgr/node_modules/dba/tunnel'
      autoload :DcNetwork, 'vnmgr/node_modules/dba/dc_network'
      autoload :Datapath, 'vnmgr/node_modules/dba/datapath'
      autoload :OpenFlowController, 'vnmgr/node_modules/dba/open_flow_controller'
      autoload :IpAddress, 'vnmgr/node_modules/dba/ip_address'
      autoload :IpLease, 'vnmgr/node_modules/dba/ip_lease'
      autoload :NetworkService, 'vnmgr/node_modules/dba/network_service'
    end
    autoload :ServiceOpenflow, 'vnmgr/node_modules/service_openflow'
  end

  module Models
    require 'json'
    autoload :Base, 'vnmgr/models/base'
    autoload :Network, 'vnmgr/models/network'
    autoload :Vif, 'vnmgr/models/vif'
    autoload :DhcpRange, 'vnmgr/models/dhcp_range'
    autoload :MacRange, 'vnmgr/models/mac_range'
    autoload :Router, 'vnmgr/models/router'
    autoload :Tunnel, 'vnmgr/models/tunnel'
    autoload :DcNetwork, 'vnmgr/models/dc_network'
    autoload :Datapath, 'vnmgr/models/datapath'
    autoload :OpenFlowController, 'vnmgr/models/open_flow_controller'
    autoload :IpAddress, 'vnmgr/models/ip_address'
    autoload :IpLease, 'vnmgr/models/ip_lease'
    autoload :NetworkService, 'vnmgr/models/network_service'
    autoload :Taggable, 'vnmgr/models/base'
  end

  module ModelWrappers
    autoload :Base, 'vnmgr/model_wrappers/base'
    autoload :NetworkWrapper, 'vnmgr/model_wrappers/network_wrapper'
    autoload :VifWrapper, 'vnmgr/model_wrappers/vif_wrapper'
    autoload :DhcpRangeWrapper, 'vnmgr/model_wrappers/dhcp_range_wrapper'
    autoload :MacRangeWrapper, 'vnmgr/model_wrappers/mac_range_wrapper'
    autoload :RouterWrapper, 'vnmgr/model_wrappers/router_wrapper'
    autoload :TunnelWrapper, 'vnmgr/model_wrappers/tunnel_wrapper'
    autoload :DcNetworkWrapper, 'vnmgr/model_wrappers/dc_network_wrapper'
    autoload :DatapathWrapper, 'vnmgr/model_wrappers/datapath_wrapper'
    autoload :OpenFlowControllerWrapper, 'vnmgr/model_wrappers/open_flow_controller_wrapper'
    autoload :IpAddressWrapper, 'vnmgr/model_wrappers/ip_address_wrapper'
    autoload :IpLeaseWrapper, 'vnmgr/model_wrappers/ip_lease_wrapper'
    autoload :NetworkServiceWrapper, 'vnmgr/model_wrappers/network_service_wrapper'
  end

  require 'vnmgr/storage_backend'
  module StorageBackends
    autoload :DBA, 'vnmgr/storage_backends/dba'
  end

  module Configurations
    require 'fuguta'
    autoload :Common,  'vnmgr/configurations/common'
    autoload :Dba,  'vnmgr/configurations/dba'
    autoload :Vnmgr,  'vnmgr/configurations/vnmgr'
  end

  module VNet
    module Openflow
      autoload :Constants, 'vnmgr/vnet/openflow/constants'
      autoload :Controller, 'vnmgr/vnet/openflow/controller'
      autoload :Datapath, 'vnmgr/vnet/openflow/datapath'
      autoload :Flow, 'vnmgr/vnet/openflow/flow'
      autoload :Network, 'vnmgr/vnet/openflow/network'
      autoload :NetworkPhysical, 'vnmgr/vnet/openflow/network_physical'
      autoload :NetworkVirtual, 'vnmgr/vnet/openflow/network_virtual'
      autoload :NetworkManager, 'vnmgr/vnet/openflow/network_manager'
      autoload :OvsOfctl, 'vnmgr/vnet/openflow/ovs_ofctl'
      autoload :Port, 'vnmgr/vnet/openflow/port'
      autoload :PortHost, 'vnmgr/vnet/openflow/port_host'
      autoload :PortLocal, 'vnmgr/vnet/openflow/port_local'
      autoload :PortPhysical, 'vnmgr/vnet/openflow/port_physical'
      autoload :PortVirtual, 'vnmgr/vnet/openflow/port_virtual'
      autoload :Switch, 'vnmgr/vnet/openflow/switch'
      autoload :TremaTasks, 'vnmgr/vnet/openflow/trema_tasks'
    end
  end

end
