# -*- coding: utf-8 -*-

module Vnet::Openflow

  # Read-only thread-safe object to allow other actors to access
  # static information about this datapath.
  class DatapathInfo

    attr_reader :dpid
    attr_reader :dpid_2

    attr_reader :id
    attr_reader :uuid
    attr_reader :display_name
    attr_reader :node_id
    attr_reader :enable_ovs_learn_action

    def initialize(dpid, dpid_s, datapath_map)
      @dpid = dpid
      @dpid_s = dpid_s

      @id = datapath_map[:id]
      @uuid = datapath_map[:uuid]
      @display_name = datapath_map[:display_name]
      @node_id = datapath_map[:node_id]
      @enable_ovs_learn_action = datapath_map[:enable_ovs_learn_action]
    end

  end

  # OpenFlow datapath allows us to send OF messages and ovs-ofctl
  # commands to a specific bridge/switch.
  class Datapath
    include Celluloid
    include Celluloid::Logger
    include FlowHelpers

    finalizer :do_cleanup

    attr_reader :dp_info
    attr_reader :datapath_info

    attr_reader :controller
    attr_reader :dpid
    attr_reader :dpid_s

    attr_reader :switch

    def initialize(ofc, dp_id, ofctl = nil)
      @dpid = dp_id
      @dpid_s = "0x%016x" % @dpid
      @controller = ofc

      @dp_info = Vnet::Core::DpInfo.new(controller: @controller,
                                        datapath: self,
                                        dpid: @dpid,
                                        ovs_ofctl: ofctl)

      @ovs_ofctl = @dp_info.ovs_ofctl
    end

    def bootstrap_init_timeout
      Vnet::Configurations::Vna.conf.bootstrap_init_timeout
    end

    def main_init_timeout
      Vnet::Configurations::Vna.conf.main_init_timeout
    end

    def create_switch
      link_with_managers(@dp_info.bootstrap_managers)
      link_with_managers(@dp_info.main_managers)

      @switch = Switch.new(self)
      link(@switch)

      @switch.create_default_flows
      @switch.switch_ready

      return nil
    end

    def run_normal
      info log_format('starting normal datapath initialization')

      begin
        info log_format("waiting for bootstrap managers to finish initialization (timeout:#{bootstrap_init_timeout})")
        @dp_info.initialize_bootstrap_managers(bootstrap_init_timeout)

        wait_for_load_of_host_datapath

        info log_format("waiting for main managers to finish initialization (timeout:#{main_init_timeout})")
        @dp_info.initialize_main_managers(@datapath_info, main_init_timeout)

        info log_format('completed normal datapath initialization')

        wait_for_unload_of_host_datapath
        info log_format('resetting datapath info')

      rescue Vnet::ManagerInitializationFailed
        warn log_format("failed to initialize some managers due to timeout")
      end

      return nil

    ensure
      # TODO: Replace with proper terminate.
      @dp_info.bootstrap_managers.each { |manager| manager.event_handler_drop_all }
      @dp_info.main_managers.each { |manager| manager.event_handler_drop_all }

      @controller.pass_task { @controller.reset_datapath(@dpid) }
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dpid_s} datapath: #{message}" + (values ? " (#{values})" : '')
    end

    def log_format_h(message, values)
      str = values.map { |value|
        value.join(':')
      }.join(' ')

      log_format(message, str)
    end

    def wait_for_load_of_host_datapath
      host_datapath = nil
      counter = 0

      while host_datapath.nil?
        info log_format('querying database for datapath with matching dpid', seconds: (counter * 30), dpid: @dpid_s)

        # TODO: Check for node id.
        host_datapath = @dp_info.host_datapath_manager.wait_for_loaded({dpid: @dpid}, 30, true)
        counter += 1
      end

      info log_format_h("found datapath info for #{@dpid_s}", host_datapath.to_h)

      @datapath_info = DatapathInfo.new(@dpid, @dpid_s, host_datapath)
    end

    def wait_for_unload_of_host_datapath
      unloaded = nil

      while unloaded.nil?
        unloaded = @dp_info.host_datapath_manager.wait_for_unloaded({id: @datapath_info.id}, nil)
      end

      debug log_format('host datapath was unloaded')
    end

    def do_cleanup
      info log_format('cleaning up')

      # We terminate the managers manually rather than relying on
      # actor's 'link' in order to ensure the managers are terminated
      # before Datapath's 'terminate' returns.
      @dp_info.terminate_main_managers
      @dp_info.terminate_bootstrap_managers
      @dp_info.del_all_flows

      info log_format('cleaned up')
    end

    def link_with_managers(managers)
      # TODO: Handle vnmgr node link differently.
      vnmgr_node = DCell::Node['vnmgr']

      if vnmgr_node.nil?
        warn log_format('could not find vnmgr dcell node, cannot create link for actor cleanup')
      end

      # The DCell messenger should not close before we have had a
      # chance to clean up all managers, however it seems to not work
      # properly.

      # vnmgr_node && vnmgr_node.link(self)

      managers.each { |manager|
        begin
          link(manager)
          vnmgr_node && vnmgr_node.link(manager)
        rescue => e
          error log_format("Fail to link with #{manager.class.name}", e)
          raise e
        end
      }
    end

  end
end
