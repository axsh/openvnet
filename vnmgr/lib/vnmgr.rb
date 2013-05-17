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
    end
  end

  module Models
    require 'json'
    autoload :Base,     'vnmgr/models/base'
    autoload :Network, 'vnmgr/models/network'
    autoload :Vif,      'vnmgr/models/vif'
    autoload :Taggable, 'vnmgr/models/base'
  end

  module Configurations
    require 'fuguta'
    autoload :Dba,  'vnmgr/configurations/dba'
  end
end
