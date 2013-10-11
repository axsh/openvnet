# -*- coding: utf-8 -*-
require 'ipaddress'

module Vnet::ModelWrappers
  class Datapath < Base
    include Helpers::IPv4
  end
end
