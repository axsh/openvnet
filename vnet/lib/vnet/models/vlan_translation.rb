# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.
  class VlanTranslation < Base
    taggable 'vt'
    many_to_one :translation
    many_to_one :network
  end
end
