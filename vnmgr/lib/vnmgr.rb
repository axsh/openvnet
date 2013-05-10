# -*- coding: utf-8 -*-

module Vnmgr

  VNMGR_ROOT = ENV['VNMGR_ROOT'] || File.expand_path('../../', __FILE__)

  module Configurations
    require 'fuguta'
    autoload :Dba, 'vnmgr/configurations/dba'
  end

  module Endpoints
    autoload :Helpers, 'vnmgr/endpoints/1.0/helpers'
    autoload :VNetAPI, 'vnmgr/endpoints/1.0/vnet_api'
  end

  module Initializers
    autoload :DB, 'vnmgr/initializers/db'
  end

  module Models
    require 'yaml'
    autoload :Base, 'vnmgr/models/base'
    autoload :Network, 'vnmgr/models/network'
    autoload :Taggable, 'vnmgr/models/base'
    autoload :Vif, 'vnmgr/models/vif'
  end

  module NodeModules
    autoload :DbAgent, 'vnmgr/node_modules/db_agent'
    autoload :ServiceOpenflow, 'vnmgr/node_modules/service_openflow'
  end

  module VNet
    module Openflow
      autoload :Constants, 'vnmgr/vnet/openflow/constants'
      autoload :Controller, 'vnmgr/vnet/openflow/controller'
      autoload :Datapath, 'vnmgr/vnet/openflow/datapath'
      autoload :Flow, 'vnmgr/vnet/openflow/flow'
      autoload :OvsOfctl, 'vnmgr/vnet/openflow/ovs_ofctl'
      autoload :Port, 'vnmgr/vnet/openflow/port'
      autoload :PortHost, 'vnmgr/vnet/openflow/port_host'
      autoload :Switch, 'vnmgr/vnet/openflow/switch'
      autoload :TremaTasks, 'vnmgr/vnet/openflow/trema_tasks'
    end
  end

end
