# -*- coding: utf-8 -*-

module Vnmgr

  VNMGR_ROOT = ENV['VNMGR_ROOT'] || File.expand_path('../../', __FILE__)

  module Endpoints
    autoload :VNetAPI, 'vnmgr/endpoints/1.0/vnet_api'
    autoload :Helpers, 'vnmgr/endpoints/1.0/helpers'
  end

  module NodeModules
    autoload :ServiceOpenflow, 'vnmgr/node_modules/service_openflow'
  end

end
