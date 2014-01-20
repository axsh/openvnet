# -*- coding: utf-8 -*-
require 'ipaddress'

module Vnet::ModelWrappers
  class Datapath < Base
    include Helpers::IPv4

    def dpid_s
      "0x%016x" % dpid
    end
  end
end
