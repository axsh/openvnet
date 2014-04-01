# -*- coding: utf-8 -*-

module Vnet::Models
  class VlanTranslation < Base
    taggable 'vt'
    many_to_one :translation
  end
end
