# -*- coding: utf-8 -*-

module Vnmgr::Models
  class NetworkService < Base
    taggable 'ns'

    many_to_one :vif

    subset(:alives, {})

  end
end
