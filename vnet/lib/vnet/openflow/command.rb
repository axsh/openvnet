# -*- coding: utf-8 -*-

#require 'trema'

module Vnet::Openflow

  class Command < Trema::Command
    include Celluloid::Logger

    attr_reader :controller

    def run(args, options)
      @args = args
      @options = options

      create_controller
      # trap_signals
      create_pid_file
      start_phut

      @controller.trema_thread = ::Thread.new {
        begin
          info "starting controller and drb threads"
          start_controller_and_drb_threads
        rescue Exception => e
          p e.inspect
          e.backtrace.each { |str| p str }
        end
      }

    rescue Trema::NoControllerDefined => e
      raise e, "#{ruby_file}: #{e.message}"
    end

    def create_controller
      debug "creating controller: #{Vnet::Openflow::Controller.name}"

      # Must have loaded the Controller subclass first to work.
      @controller = Trema::Controller.create(6633, :debug)
    end

  end
end

