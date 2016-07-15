# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Datapath < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(datapath)
      argument_type_check(datapath, Vnet::ModelWrappers::Datapath)
      datapath.to_hash.merge({ dpid: datapath.dpid_s })
    end
  end

  class DatapathCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i| Datapath.generate(i) }
    end
  end

  class DatapathSegment < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object, Vnet::ModelWrappers::DatapathSegment)
      object.to_hash
    end
  end

  class DatapathSegmentCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        DatapathSegment.generate(i)
      }
    end
  end
end
