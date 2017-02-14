# -*- coding: utf-8 -*-

module Vnet::Models
  class Translation < Base
    taggable 'tr'
    plugin :paranoia_is_deleted

    use_modes Vnet::Constants::Translation::MODES

    one_to_many :translation_static_addresses

    many_to_one :interface

    plugin :association_dependencies,
    # 0001_origin
    translation_static_addresses: :destroy

  end
end
