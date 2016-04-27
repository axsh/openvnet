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
      mode.option :ipv4_address, :type => :string,
        :desc => "This is the ipv4 address the filter will be applied on."
      mode.option :protocol, :type => :string, :required => true,
        :desc => "This is the protocol which the filter will listen on."
      mode.option :port_number, :type => :string,
        :desc => "This is the port number the filter will listen on." 
      mode.option :passthrough, :type => :boolean,
        :desc => "Flag that controlls where the static should pass or drop data for specified rule."
      
      
      mode.option :ipv4_src_address, :type => :string,
        :desc => "This is the address the filter will apply for incoming traffic."
      mode.option :ipv4_dst_address, :type => :string,
        :desc => "This is the address the filter will apply for outgoing traffic."
      mode.option :port_src, :type => :string,
        :desc => "This is the port which the rule will apply to for incoming traffic."
      mode.option :port_dst, :type => :string,
        :desc => "This is the port which the rule will apply to for outgoing traffic."
    end
  end
end
