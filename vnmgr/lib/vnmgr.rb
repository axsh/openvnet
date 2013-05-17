# -*- coding: utf-8 -*-

module Vnmgr

  VNMGR_ROOT = ENV['VNMGR_ROOT'] || File.expand_path('../../', __FILE__)

  module Initializers
    autoload :DB, 'vnmgr/initializers/db'
  end

  module Endpoints
    autoload :VNetAPI, 'vnmgr/endpoints/1.0/vnet_api'
    autoload :Helpers, 'vnmgr/endpoints/1.0/helpers'
  end

  module NodeModules
    autoload :DbAgent,	'vnmgr/node_modules/db_agent'
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
    end
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
    autoload :Taggable, 'vnmgr/models/base'
  end

  module Configurations
    require 'fuguta'
    autoload :Dba,  'vnmgr/configurations/dba'
    autoload :Vnmgr,  'vnmgr/configurations/vnmgr'
  end
end
