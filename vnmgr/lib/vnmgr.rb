# -*- coding: utf-8 -*-

module Vnmgr

  module Endpoints
    autoload :VNetAPI, 'dcmgr/endpoints/vnet_api'
  end

	module NodeModules
		autoload :DbAgent,	'vnmgr/node_modules/db_agent'
	end
end
