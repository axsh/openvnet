# -*- coding: utf-8 -*-

module Vnmgr

  VNMGR_ROOT = ENV['VNMGR_ROOT'] || File.expand_path('../../', __FILE__)

  module Endpoints
    autoload :VNetAPI, 'vnmgr/endpoints/vnet_api'
    autoload :Helpers, 'vnmgr/endpoints/helpers'
  end

	module NodeModules
		autoload :DbAgent,	'vnmgr/node_modules/db_agent'
	end

  module Models
    require 'yaml'
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
