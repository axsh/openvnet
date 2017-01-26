# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Segment < Base
    namespace :segments
    api_suffix 'segments'

    option_uuid
    option :mode, type: :string, required: true, desc: 'Can be either physical or virtual.'
    define_add

    define_show
    define_del
  end
end
