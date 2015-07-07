# -*- coding: utf-8 -*-

module VNetAPIClient

  class Datapath < ApiResource
    define_standard_crud_methods

    class << self

      def add_network(datapath_id, network_id, params = nil)
        suffix = "datapaths/#{datapath_id}/networks/#{network_id}"
        send_request(Net::HTTP::Post, suffix, params)
      end

      def show_networks(datapath_id)
        send_request(Net::HTTP::Get, "datapaths/#{datapath_id}/networks")
      end

      def remove_network(datapath_id, network_id)
        suffix = "datapaths/#{datapath_id}/networks/#{network_id}"
        send_request(Net::HTTP::Delete, suffix)
      end

    end
  end

end
