# -*- coding: utf-8 -*-
require 'ipaddress'

module Vnet::ModelWrappers

  class Datapath < Base
    include Helpers::IPv4

    def dpid_s
      "0x%016x" % dpid
    end
  end

  class DatapathNetwork < Base
  end

  class DatapathSegment < Base
  end

  class DatapathRouteLink < Base
  end

end
