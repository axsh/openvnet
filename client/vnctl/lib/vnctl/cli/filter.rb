module Vnctl::Cli
  class Filter < Base
    namespace :filters
    api_suffix "filters"

    add_modify_shared_options {
      option :interface_uuid, :type => :string, :desc => "This interface uuid that will use this filter."
      option :mode, :type => :string, :desc => "The mode for this translation."
      option :egress_passthrough, :type => :boolean, :desc => "Flag that sets if outgoing data will pass through or be dropped."
      option :ingress_passthrough, :type => :boolean, :desc => "Flag that sets if incoming data will pass through or be dropped."
      option :ipv4_address, :type => :string, :desc => "This is the ip address which the filter will listen to."
      option :port_number, :type => :string, :desc => "This is the port for which to the filter will listen to."
    }

    set_required_options [:interface_uuid, :mode, :pass]

    define_standard_crud_commands

    #TODO Write the static addresses thingy
  end
end
