# -*- coding: utf-8 -*-

module Vnet::Models
  class Segment < Base
    taggable 'seg'
    plugin :paranoia_is_deleted

    # plugin :association_dependencies,

  end
end
