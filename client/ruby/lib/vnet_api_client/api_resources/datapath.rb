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

    end
  end

end
