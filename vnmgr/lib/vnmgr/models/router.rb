# -*- coding: utf-8 -*-

module Vnmgr::Models
  class Router < Base
    taggable 'r'
    many_to_one :network
  end
end
