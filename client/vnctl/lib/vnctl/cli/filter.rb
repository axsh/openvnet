module Vnctl::Cli
  class Filter < Base
    namespace :filters
    api_suffix "filters"

    add_modify_shared_options {
      option :interface_uuid, :type => :string, :desc => "This interface uuid that will use this filter."
      option :mode, :type => :string, :desc => "The mode for this translation."
      option :egress_passthrough, :type => :boolean, :desc => "Flag that sets if outgoing data will pass through or be dropped."
      option :ingress_passthrough, :type => :boolean, :desc => "Flag that sets if incoming data will pass through or be dropped."
    }

    set_required_options [:interface_uuid, :mode]

    define_standard_crud_commands

    define_mode_relation(:static) do | mode |
#      mode.option :filter_uuid, :type => :string, :desc => "This is the filter that will be activated."
      mode.option :ipv4_address, :type => :string, :required => true,
        :desc => "This is the ipv4 address the filter will be applied on."
      mode.option :protocol, :type => :string, :required => true,
        :desc => "This is the protocol which the filter will listen on."
      mode.option :port_number, :type => :string,
        :desc => "This is the port number the filter will listen on."
    end
    
    #TODO Write the static thingy
  end
end
