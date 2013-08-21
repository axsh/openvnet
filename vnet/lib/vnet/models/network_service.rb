# -*- coding: utf-8 -*-

module Vnet::Models
  class NetworkService < Base
    taggable 'ns'

    many_to_one :iface

    subset(:alives, {})

  end
end
