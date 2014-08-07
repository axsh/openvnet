# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.
  class VlanTranslation < Base
    taggable 'vt'
    many_to_one :translation
  end
end
