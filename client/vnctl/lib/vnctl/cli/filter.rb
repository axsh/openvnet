module Vnctl::Cli
  class Filter < Base
    namespace :filters
    api_suffix "filters"

    add_shared_options {
      option :interface_uuid, :type => :string, :required => true,
        :desc => "This interface uuid that will use this filter."
      option :mode, :type => :string, :required => true,
        :desc => "The mode for this translation."
    }

    add_modify_shared_options {
      option :egress_passthrough, :type => :boolean, :desc => "Flag that sets if outgoing data will pass through or be dropped."
      option :ingress_passthrough, :type => :boolean, :desc => "Flag that sets if incoming data will pass through or be dropped."
    }

    define_standard_crud_commands

    define_mode_relation(:static) do | mode |
      mode.option :ipv4_address, :type => :string,
        :desc => "This is the ipv4 address the filter will be applied on."
      mode.option :protocol, :type => :string, :required => true,
        :desc => "This is the protocol which the filter will listen on."
      mode.option :port_number, :type => :string,
        :desc => "This is the port number the filter will listen on."
      mode.option :passthrough, :type => :boolean,
        :desc => "Flag that controls where the static should pass or drop data for specified rule."
    end
  end
end
