# -*- coding: utf-8 -*-

module Vnet::Models

  class ActiveInterface < Base
    many_to_one :interface
    many_to_one :datapath

  end

end
