# -*- coding: utf-8 -*-

module Vnet::Openflow

  # Read-only thread-safe object to allow other actors to access
  # static information about this datapath.
  class DatapathInfo

    attr_reader :id
    attr_reader :uuid
    attr_reader :display_name
    attr_reader :node_id

    def initialize(datapath_map)
      @id = datapath_map[:id]
      @uuid = datapath_map[:uuid]
      @display_name = datapath_map[:display_name]
      @node_id = datapath_map[:node_id]
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

    def create_switch
      link_with_managers(@dp_info.bootstrap_managers)
      link_with_managers(@dp_info.managers)

      @switch = Switch.new(self)
      link(@switch)
      
      @switch.create_default_flows
      @switch.switch_ready

      return nil
    end

    def run_normal
      info log_format('starting normal vnet datapath')
      
      wait_for_load_of_host_datapath
      initialize_managers
      wait_for_unload_of_host_datapath

      info log_format('resetting datapath info')

      @dp_info.managers.each { |manager|
        manager.event_handler_drop_all
      }

      @controller.pass_task { @controller.reset_datapath(@dpid) }

      return nil
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dpid_s} datapath: #{message}" + (values ? " (#{values})" : '')
    end

    def wait_for_load_of_host_datapath
      host_datapath = nil
      counter = 0

      while host_datapath.nil?
        info log_format('querying database for datapath with matching dpid', "seconds:#{counter * 30}")

        # TODO: Check for node id.
        host_datapath = @dp_info.host_datapath_manager.wait_for_loaded({dpid: @dpid}, 30, true)
        counter += 1
      end

      @datapath_info = DatapathInfo.new(host_datapath)

      # Make sure datapath manager has the host datapath.
      #
      # TODO: This should be done automatically by datapath manager
      # when it is initialized.
      # 
      # Since we load the host datapath here, we need to set
      # queue-only now.
      @dp_info.managers.each { |manager|
        manager.event_handler_queue_only
      }

      @dp_info.datapath_manager.async.retrieve(dpid: @dpid)
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
      @dp_info.terminate_managers
      @dp_info.del_all_flows

      info log_format('cleaned up')
    end

    def link_with_managers(managers)
      vnmgr_node = DCell::Node[:vnmgr]

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

    # TODO: Call this from somewhere.
    def initialize_bootstrap_managers
      managers = @dp_info.bootstrap_managers
      managers.each { |manager| manager.set_datapath_info(@datapath_info) }
      managers.each { |manager| manager.event_handler_queue_only }
      managers.each { |manager| manager.async.start_initialize }
      managers.each { |manager| manager.wait_for_initialized(nil) }
      managers.each { |manager| manager.event_handler_active }
    end

    def initialize_managers
      managers = @dp_info.managers
      managers.each { |manager| manager.set_datapath_info(@datapath_info) }
      managers.each { |manager| manager.event_handler_queue_only }
      managers.each { |manager| manager.async.start_initialize }
      managers.each { |manager| manager.wait_for_initialized(nil) }
      managers.each { |manager| manager.event_handler_active }
    end

  end
end
