# -*- coding: utf-8 -*-

module Vnet::Models

  class Topology < Base
    taggable 'tp'

    plugin :paranoia_is_deleted

  end

end
