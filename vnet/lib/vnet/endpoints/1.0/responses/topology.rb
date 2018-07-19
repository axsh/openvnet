# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Topology < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object, Vnet::ModelWrappers::Topology)
      object.to_hash
    end
  end

  class TopologyCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array, Array)
      array.map { |i| Topology.generate(i) }
    end
  end

  class TopologyDatapath < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::TopologyDatapath)
      object.to_hash.tap { |res|
        # TODO: This is both slow and verbose.
        # datapath = object.batch.datapath.commit
        # res[:datapath_uuid] = datapath.uuid if datapath
      }
    end
  end

  class TopologyDatapathCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        TopologyDatapath.generate(i)
      }
    end
  end

  class TopologyLayer < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::TopologyLayer)
      object.to_hash.tap { |res|
      }
    end
  end

  class TopologyLayerCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        TopologyLayer.generate(i)
      }
    end
  end

  class TopologyMacRangeGroup < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::TopologyMacRangeGroup)
      object.to_hash.tap { |res|
      }
    end
  end

  class TopologyMacRangeGroupCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        TopologyMacRangeGroup.generate(i)
      }
    end
  end

  class TopologyNetwork < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::TopologyNetwork)
      object.to_hash.tap { |res|
        # TODO: This is both slow and verbose.
        # network = object.batch.network.commit
        # res[:network_uuid] = network.uuid if network
      }
    end
  end

  class TopologyNetworkCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        TopologyNetwork.generate(i)
      }
    end
  end

  class TopologySegment < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::TopologySegment)
      object.to_hash.tap { |res|
        # TODO: This is both slow and verbose.
        # segment = object.batch.segment.commit
        # res[:segment_uuid] = segment.uuid if segment
      }
    end
  end

  class TopologySegmentCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        TopologySegment.generate(i)
      }
    end
  end

  class TopologyRouteLink < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::TopologyRouteLink)
      object.to_hash.tap { |res|
        # TODO: This is both slow and verbose.
        # network = object.batch.network.commit
        # res[:network_uuid] = network.uuid if network
      }
    end
  end

  class TopologyRouteLinkCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i|
        TopologyRouteLink.generate(i)
      }
    end
  end

end
