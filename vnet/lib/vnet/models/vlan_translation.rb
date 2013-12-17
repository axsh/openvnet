# -*- coding: utf-8 -*-

module Vnet::Models
  class VlanTranslation < Base
    many_to_one :translation
  end
end
