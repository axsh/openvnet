# -*- coding: utf-8 -*-

module Vnet::Models
  class Filter < Base
    taggable 'fil'
    plugin :paranoia_is_deleted

    # TODO: Disabling 'use_modes' until specs are fixed.
    # use_modes Vnet::Constants::Filter::MODES

    one_to_many :filter_statics

    many_to_one :interface

    plugin :association_dependencies,
    # 0006_filters
    filter_statics: :destroy

  end
end
