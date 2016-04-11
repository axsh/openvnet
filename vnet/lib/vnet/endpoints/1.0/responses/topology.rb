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
