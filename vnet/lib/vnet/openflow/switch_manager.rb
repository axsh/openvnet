# -*- coding: utf-8 -*-

require 'nio'
require 'trema'
require "trema/dsl/context"
require "trema/util"

module Vnet::Openflow
  class SwitchManager
    include Trema::Util

    def configure_trema
      # Trema hack...
      $verbose = true

      conf = Vnet::Configurations::Vna.conf
      ENV['TREMA_HOME'] ||= conf.trema_home
      ENV['TREMA_TMP'] ||= conf.trema_tmp
      %w(log pid sock).each do |name|
        FileUtils.mkdir_p(File.join(ENV['TREMA_TMP'], name))
      end
    end

    def start
      if defined?(::Celluloid)
        raise "Celluloid module loaded before SwitchManager has started."
      end

      bridge_sockets = self.list_bridge_sockets
      bridge_sockets.each { |path| FileUtils.remove_file(path, true) }

      raise "No OVS bridges defined." if bridge_sockets.empty?

      rule = {
        :port_status => "Controller",
        :packet_in => "Controller",
        :state_notify => "Controller",
        :vendor => "Controller"
      }

      # @switch_manager = Trema::SwitchManager.new( rule, nil, bridge_sockets.last )
      @switch_manager = Trema::SwitchManager.new( rule, 6633, nil )
      # @switch_manager.command_prefix = "valgrind -q --tool=memcheck --leak-check=yes --trace-children=yes --log-socket=127.0.0.1:12345 "

      system(@switch_manager.command + " --no-cookie-translation")
    end

    def do_cleanup
      cleanup_current_session
    end

    def kill_old_switches
      Dir.glob(File.join(Trema.pid, "*.pid")).each do | each |
        # logger.info "trema kill: pid_file:'#{each}'."
        # info "trema kill: pid_file:'#{each}'."
        pid = ::IO.read( each ).chomp.to_i
        system("kill #{pid}") if pid != 0
      end
    end

    def list_bridge_sockets
      # Dcmgr.conf.dc_networks.values.keep_if { |dcn|
      #   dcn.bridge_type == 'ovs' and !dcn.name.empty?
      # }.map { |dcn|
      #   dcn.bridge
      # }.uniq.map { |bridge|
      #   "#{Dcmgr.conf.ovs_run_dir}/#{bridge}.controller"
      # }
      ['/var/run/openvswitch/br0.controller']
    end

  end
end
