# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Translation < Base
    namespace :translations
    api_suffix "/api/translations"

    add_modify_shared_options {
      option :interface_uuid, :type => :string, :desc => "This interface uuid for this translation."
      option :mode, :type => :string, :desc => "The mode for this translation."
      option :passthrough, :type => :boolean, :desc => "Flag that sets if this translation is passthrough or not."
    }

    set_required_options [:interface_uuid, :mode]

    define_standard_crud_commands

    #TODO Write the static addresses thingy
  end
end
