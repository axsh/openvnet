# -*- coding: utf-8 -*-

require 'ext/kernel'

module Vnmgr

  VNMGR_ROOT = ENV['VNMGR_ROOT'] || File.expand_path('../../', __FILE__)

  module Initializers
    autoload :DB, 'vnmgr/initializers/db'
  end

  module Endpoints
    autoload :ResponseGenerator, 'vnmgr/endpoints/response_generator'
    autoload :Errors, 'vnmgr/endpoints/errors'
    module V10
      autoload :VNetAPI, 'vnmgr/endpoints/1.0/vnet_api'
      autoload :Helpers, 'vnmgr/endpoints/1.0/helpers'

      module Responses
        autoload :Network, 'vnmgr/endpoints/1.0/responses/network'
        autoload :NetworkCollection, 'vnmgr/endpoints/1.0/responses/network'
      end
    end
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

  module ModelWrappers
    autoload :Base, 'vnmgr/model_wrappers/base'
    autoload :NetworkWrapper, 'vnmgr/model_wrappers/network_wrapper'
  end

  module Configurations
    require 'fuguta'
    autoload :Dba,  'vnmgr/configurations/dba'
    autoload :Vnmgr,  'vnmgr/configurations/vnmgr'
  end
end
