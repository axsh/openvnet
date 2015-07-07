# -*- coding: utf-8 -*-

module VNetAPIClient

  class Datapath < ApiResource
    class << self

      def create(params = nil)
        send_request(Net::HTTP::Post, 'datapaths', params)
      end

      def update(datapath_id, params = nil)
        send_request(Net::HTTP::Put, "datapaths/#{datapath_id}", params)
      end

      def delete(datapath_id)
        send_request(Net::HTTP::Delete, "datapaths/#{datapath_id}")
      end

      def show(datapath_id)
        send_request(Net::HTTP::Get, "datapaths/#{datapath_id}")
      end

      def index
        send_request(Net::HTTP::Get, 'datapaths')
      end

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
