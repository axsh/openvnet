# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Datapath < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(datapath)
      argument_type_check(datapath, Vnet::ModelWrappers::Datapath)
      datapath.dc_segment_uuid = datapath.dc_segment.uuid if datapath.dc_segment
      datapath.to_hash.merge({ dpid: datapath.dpid_s })
    end
  end

  class DatapathCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i| Datapath.generate(i) }
    end
  end
end
