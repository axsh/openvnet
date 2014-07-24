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
      @lock = Mutex.new

      @lock.synchronize {
        @dpid = dp_id
        @dpid_s = "0x%016x" % @dpid
        @controller = ofc

        @dp_info = Vnet::Core::DpInfo.new(controller: @controller,
                                          datapath: self,
                                          dpid: @dpid,
                                          ovs_ofctl: ofctl)

        @ovs_ofctl = @dp_info.ovs_ofctl

        link_with_managers
      }
    end

    def create_switch
      @lock.synchronize {
        @switch = Switch.new(self)
        @switch.create_default_flows

        @switch.switch_ready
      }

      if @dp_info.datapath_manager.retrieve(dpid: @dpid).nil?
        warn log_format('could not find dpid in database')
      end

      return
    end

    # We use a lock to avoid datapath_manager from from initializing
    # datapath_info before the Datapath has finished initializing.
    def initialize_datapath_info(datapath_map)
      @lock.synchronize {
        info log_format('initializing datapath info')

        if @datapath_info
          info log_format('tried to reinitialize an already initialized datapath, resetting')
          @controller.pass_task { @controller.reset_datapath(@dpid) }
          next false
        end

        @datapath_info = DatapathInfo.new(datapath_map)

        initialize_managers
        next true
      }
    end

    def reset_datapath_info
      @lock.synchronize {
        info log_format('resetting datapath info')

        @controller.pass_task { @controller.reset_datapath(@dpid) }
      }
      return
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dpid_s} datapath: #{message}" + (values ? " (#{values})" : '')
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

    def link_with_managers
      @dp_info.managers.each { |manager|
        begin
          link(manager)
        rescue => e
          error "Fail to link with #{manager.class.name}: #{e}"
          raise e
        end
      }
    end

    # TODO: Add a way to block events from being processed by managers
    # until everything has been initialized.
    def initialize_managers
      @dp_info.managers.each { |manager|
        manager.set_datapath_info(@datapath_info)
      }

      # Until we have datapath_info loaded none of the ports can be
      # initialized.
      @dp_info.port_manager.initialize_ports
      @dp_info.interface_port_manager.load_internal_interfaces
    end

  end

end
