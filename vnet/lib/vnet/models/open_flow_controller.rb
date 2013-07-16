# -*- coding: utf-8 -*-

module Vnet::Models
  class OpenFlowController < Base
    taggable 'ofc'
    one_to_many :datapath
  end
end
