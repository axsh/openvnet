# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Segment < Base
    namespace :segments
    api_suffix 'segments'

    add_shared_options {
      option :topology_uuid, :type => :string, :desc => "The uuid of the topology this network is in."
      option :mode, type: :string, required: true, desc: 'Can be either physical or virtual.'
    }

    option_uuid
    add_shared_options
    define_add

    define_show
    define_del
  end
end
