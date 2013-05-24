# -*- coding: utf-8 -*-

module Vnmgr::Models
  class Tunnel < Base
    taggable 't'
    many_to_one :network
  end
end
