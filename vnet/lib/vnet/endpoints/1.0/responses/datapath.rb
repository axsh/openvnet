# -*- coding: utf-8 -*-

module Vnet::Endpoints::V10::Responses
  class Datapath < Vnet::Endpoints::ResponseGenerator
    def self.generate(datapath)
      argument_type_check(datapath, Vnet::ModelWrappers::Datapath)
      datapath.to_hash.merge({ dpid: datapath.dpid_s })
    end

    def self.networks(datapath)
      argument_type_check(datapath,Vnet::ModelWrappers::Datapath)
      {
        :uuid => datapath.uuid,
        :networks => DatapathNetworkCollection.generate(
          datapath.batch.datapath_networks.commit
        )
      }
    end

    def self.route_links(datapath)
      argument_type_check(datapath,Vnet::ModelWrappers::Datapath)
      {
        :uuid => datapath.uuid,
        :route_links => DatapathRouteLinkCollection.generate(
          datapath.batch.datapath_route_links.commit
        )
      }
    end
  end

  class DatapathCollection < Vnet::Endpoints::ResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i| Datapath.generate(i) }
    end
  end
end
