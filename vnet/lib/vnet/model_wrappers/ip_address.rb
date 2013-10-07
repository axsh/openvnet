# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class IpAddress < Base
    include Helpers::IPv4
  end
end
