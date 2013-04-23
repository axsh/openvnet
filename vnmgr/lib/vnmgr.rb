# -*- coding: utf-8 -*-

module Vnmgr

  VNMGR_ROOT = ENV['VNMGR_ROOT'] || File.expand_path('../../', __FILE__)

  module Endpoints
    autoload :VNetAPI, 'dcmgr/endpoints/vnet_api'
  end

	module NodeModules
		autoload :DbAgent,	'vnmgr/node_modules/db_agent'
	end

  module Models
    require 'yaml'
    autoload :Base,     'vnmgr/models/base'
    autoload :Network, 'vnmgr/models/network'
    autoload :Taggable, 'vnmgr/models/base'
  end
end
