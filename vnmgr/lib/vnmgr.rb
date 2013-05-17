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
      end
    end
  end

  module NodeModules
    autoload :DbAgent,	'vnmgr/node_modules/db_agent'
    module DBA
      autoload :Base, 'vnmgr/node_modules/dba/base'
      autoload :Network, 'vnmgr/node_modules/dba/network'
      autoload :Vif, 'vnmgr/node_modules/dba/vif'
    end
  end

  module Models
    require 'json'
    autoload :Base, 'vnmgr/models/base'
    autoload :Network, 'vnmgr/models/network'
    autoload :Vif, 'vnmgr/models/vif'
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
  end

  require 'vnmgr/storage_backend'
  module StorageBackends
    autoload :DBA, 'vnmgr/storage_backends/dba'
  end

  module Configurations
    require 'fuguta'
    autoload :Dba,  'vnmgr/configurations/dba'
    autoload :Vnmgr,  'vnmgr/configurations/vnmgr'
  end
end
