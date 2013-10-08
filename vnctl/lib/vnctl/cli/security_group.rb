# -*- coding: utf-8 -*-

module Vnctl::Cli
  class SecurityGroup < Base
    namespace :security_group
    api_suffix "/api/security_groups"

    add_modify_shared_options {
      option_display_name
      option_description
    }

    add_required_options [:display_name]

    define_standard_crud_commands
  end
end
