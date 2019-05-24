# -*- coding: utf-8 -*-

# Thread-safe access to static information on the datapath and
# managers. No writes are done to this instance after the creation of
# the datapath.
#
# Since this isn't an actor we avoid the need to go through the
# Datapath actor's messaging queue for every time we use a manager.

module Vnet::Core
  class DpInfo
    include Vnet::ManagerList

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

    MAIN_MANAGER_NAMES = %w(
      active_interface
      active_network
      active_port
      active_route_link
      active_segment
      datapath
      interface
      interface_network
      interface_segment
      interface_route_link
      interface_port
      network
      route
      router
      filter
      segment
      service
      tunnel
      translation
      port
    ).freeze

    MAIN_MANAGER_NAMES.each do |name|
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
      internal_initialize_managers(MAIN_MANAGER_NAMES)
    end

    def inspect
      "<##{self.class.name} dpid:#{@dpid}>"
    end

    #
    # Flow modification:
    #

    def add_flow(flow)
      @controller.public_add_flow(@dpid, flow)
    end

    def add_flows(flows)
      @controller.public_add_flows(@dpid, flows)
    end

    def add_ovs_flow(flow_str)
      @ovs_ofctl.add_ovs_flow(flow_str)
    end

    def add_ovs_10_flow(flow_str)
      @ovs_ofctl.add_ovs_10_flow(flow_str)
    end

    def del_cookie(cookie, cookie_mask = Vnet::Constants::OpenflowFlows::COOKIE_MASK)
      params = {
        :cookie => cookie,
        :cookie_mask => cookie_mask
      }

      @controller.send_flow_mod_delete(@dpid, params)
    end

    def del_flows(params = {})
      @controller.send_flow_mod_delete(@dpid, params.merge(match: Pio::Match.new(params[:match] || {})))
    end

    def del_all_flows
      options = {
        table_id: 0xff,
        match: {
        },
      }

      @controller.public_send_flow_mod_delete(@dpid, options)
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
      @controller.public_send_message(@dpid, message)
    end

    def send_packet_out(message, port_no)
      @controller.public_send_packet_out(@dpid, message, port_no)
    end

    #
    # Managers:
    #

    def bootstrap_managers
      BOOTSTRAP_MANAGER_NAMES.map { |name| __send__("#{name}_manager") }
    end

    def main_managers
      MAIN_MANAGER_NAMES.map { |name| __send__("#{name}_manager") }
    end

    def initialize_bootstrap_managers(timeout, interval = 10.0)
      initialize_manager_list(bootstrap_managers, timeout, interval)
    end

    def initialize_main_managers(datapath_info, timeout, interval = 10.0)
      initialize_manager_list(main_managers, timeout, interval) { |manager|
        manager.set_datapath_info(datapath_info)
      }

      datapath_manager.async.retrieve(dpid: datapath_info.dpid)
    end

    def terminate_all_managers(timeout = 10.0)
      terminate_manager_list(main_managers + bootstrap_managers, timeout)
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dpid_s} dp_info: #{message}" + (values ? " (#{values})" : '')
    end

    def internal_initialize_managers(name_list)
      name_list.each { |name|
        instance_variable_set("@#{name}_manager", Vnet::Core.const_get("#{name.to_s.camelize}Manager").new(self))
      }
    end

  end

end
