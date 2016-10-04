# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Segment < Base
    namespace :segments
    api_suffix 'segments'

    add_modify_shared_options {
      option :mode, :type => :string, :desc => 'Can be either physical or virtual.'
    }

    set_required_options [:mode]

    define_standard_crud_commands
  end
end
