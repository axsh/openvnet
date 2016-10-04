# -*- coding: utf-8 -*-

# Thread-safe access to static information on the datapath and
# managers. No writes are done to this instance after the creation of
# the datapath.
#
# Since this isn't an actor we avoid the need to go through the
# Datapath actor's messaging queue for every time we use a manager.

module Vnet::Core

  class DpInfo

    BOOTSTRAP_MANAGER_NAMES = %w(
      host_datapath
    ).freeze

    BOOTSTRAP_MANAGER_NAMES.each do |name|
      attr_reader "#{name}_manager"
    end

    # Port manager is always last in order to ensure that all other
    # managers have valid datapath_info before ports are initialized.
    #
    # TODO: Port manager should be moved to bootstrap.

    MANAGER_NAMES = %w(
      active_interface
      active_network
      active_port
      active_route_link
      active_segment
      connection
      datapath
      interface
      interface_segment
      interface_port
      network
      route
      router
      filter2
      filter
      segment
      service
      tunnel
      translation
      port
    ).freeze

    MANAGER_NAMES.each do |name|
      attr_reader "#{name}_manager"
    end

    attr_reader :controller
    attr_reader :datapath

    attr_reader :dpid
    attr_reader :dpid_s
    attr_reader :ovs_ofctl

    def initialize(params)
      @dpid = params[:dpid]
      @dpid_s = "0x%016x" % @dpid

      @controller = params[:controller]
      @datapath = params[:datapath]
      @ovs_ofctl = params[:ovs_ofctl]

      internal_initialize_managers(BOOTSTRAP_MANAGER_NAMES)
      internal_initialize_managers(MANAGER_NAMES)
    end

    def inspect
      "<##{self.class.name} dpid:#{@dpid}>"
    end

    #
    # Flow modification:
    #

    def add_flow(flow)
      @controller.pass_task {
        @controller.send_flow_mod_add(@dpid, flow.to_trema_hash)
      }
    end

    def add_flows(flows)
      return if flows.blank?

      @controller.pass_task {
        flows.each { |flow|
          @controller.send_flow_mod_add(@dpid, flow.to_trema_hash)
        }
      }
    end

    def add_ovs_flow(flow_str)
      @ovs_ofctl.add_ovs_flow(flow_str)
    end

    def add_ovs_10_flow(flow_str)
      @ovs_ofctl.add_ovs_10_flow(flow_str)
    end

    def del_cookie(cookie, cookie_mask = Vnet::Constants::OpenflowFlows::COOKIE_MASK)
      options = {
        :command => Vnet::Openflow::Controller::OFPFC_DELETE,
        :table_id => Vnet::Openflow::Controller::OFPTT_ALL,
        :out_port => Vnet::Openflow::Controller::OFPP_ANY,
        :out_group => Vnet::Openflow::Controller::OFPG_ANY,
        :cookie => cookie,
        :cookie_mask => cookie_mask
      }

      @controller.pass_task {
        @controller.public_send_flow_mod(@dpid, options)
      }
    end

    def del_flows(params = {})
      options = {
        :command => Vnet::Openflow::Controller::OFPFC_DELETE,
        :table_id => Vnet::Openflow::Controller::OFPTT_ALL,
        :out_port => Vnet::Openflow::Controller::OFPP_ANY,
        :out_group => Vnet::Openflow::Controller::OFPG_ANY,
      }.merge(params)

      match = options[:match]
      options[:match] = Trema::Match.new(match) if match

      @controller.pass_task {
        @controller.public_send_flow_mod(@dpid, options)
      }
    end

    def del_all_flows
      options = {
        :command => Vnet::Openflow::Controller::OFPFC_DELETE,
        :table_id => Vnet::Openflow::Controller::OFPTT_ALL,
        :out_port => Vnet::Openflow::Controller::OFPP_ANY,
        :out_group => Vnet::Openflow::Controller::OFPG_ANY,
      }

      @controller.pass_task {
        @controller.public_send_flow_mod(@dpid, options)
      }
    end

    #
    # Port modification methods:
    #

    def add_tunnel(tunnel_name, params = {})
      # debug log_format('adding tunnel', "#{tunnel_name}")
      @ovs_ofctl.add_tunnel(tunnel_name, params)
    end

    def delete_tunnel(tunnel_name)
      # debug log_format('deleting tunnel', "#{tunnel_name}")
      @ovs_ofctl.delete_tunnel(tunnel_name)
    end

    #
    # Trema messaging:
    #

    def send_message(message)
      @controller.pass_task {
        @controller.public_send_message(@dpid, message)
      }
    end

    def send_packet_out(message, port_no)
      @controller.pass_task {
        @controller.public_send_packet_out(@dpid, message, port_no)
      }
    end

    #
    # Managers:
    #

    def managers
      MANAGER_NAMES.map { |name| __send__("#{name}_manager") }
    end

    def bootstrap_managers
      BOOTSTRAP_MANAGER_NAMES.map { |name| __send__("#{name}_manager") }
    end

    def terminate_managers(timeout = 10.0)
      internal_terminate_managers(managers, timeout)
    end

    def terminate_bootstrap_managers(timeout = 10.0)
      internal_terminate_managers(bootstrap_managers, timeout)
    end

    #
    # Internal methods:
    #

    private

    def internal_initialize_managers(name_list)
      name_list.each { |name|
        instance_variable_set("@#{name}_manager", Vnet::Core.const_get("#{name.to_s.camelize}Manager").new(self))
      }
    end

    def internal_terminate_managers(manager_list, timeout)
      manager_list.each { |manager|
        begin
          manager.terminate
        rescue Celluloid::DeadActorError
        end
      }

      start_time = Time.new

      manager_list.each { |manager|
        next_timeout = timeout - (Time.new - start_time)

        Celluloid::Actor.join(manager, (next_timeout < 0.1) ? 0.1 : next_timeout)
      }
    end

  end

end
