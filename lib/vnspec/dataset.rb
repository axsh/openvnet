# -*- coding: utf-8 -*-
module Vnspec
  class Dataset
    include Logger
    include Config

    class << self
      def setup(name)
        self.new(name).setup
      end

    end

    attr_reader :name
    attr_reader :dataset
    attr_reader :options

    def initialize(name)
      @name = name
      @options = config[:dataset_options]
      init_dataset
    end

    def setup
      @dataset.each do |key, value|
        value.each do |v|
          v = v.dup
          url = case key
          when :datapath_networks
            "datapaths/#{v.delete(:datapath_uuid)}/networks/#{v.delete(:network_uuid)}"
          when :datapath_route_links
            "datapaths/#{v.delete(:datapath_uuid)}/route_links/#{v.delete(:route_link_uuid)}"
          else
            key.to_s
          end
          request(:post, url, v)
        end
      end
    end

    def request(method, url, params = {}, headers = {}, &block)
      API.request(method, url, params, headers, &block)
    end

    private
    def init_dataset
      @dataset = ["base", name].inject({}) do |h, n|
        h.merge(load_file(n))
      end
    end

    def load_file(name)
      file = File.expand_path(File.join("../../dataset", "#{name}.yml"), File.dirname(__FILE__))
      body = ERB.new(File.open(file).read).result_hash(options)
      YAML.load(body).symbolize_keys
    end
  end
end
