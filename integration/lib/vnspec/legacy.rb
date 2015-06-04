# -*- coding: utf-8 -*-
module Vnspec
  class Legacy
    include Config
    include SSH
    include Logger

    class << self
      include Config
      include Logger

      def setup
        @@legacy_machines = []
        config[:legacy_machines].keys.map do |m|
          @@legacy_machines << self.new(m)
        end
      end

      def find(name)
        @@legacy_machines.find { |m| m.name == name }
      end
      alias :[] :find
    end

    attr_reader :name
    attr_reader :hostname
    attr_reader :ssh_ip
    attr_reader :ipv4_address

    def initialize(name)
      @name = name.to_sym
      @hostname = config[:legacy_machines][name][:hostname] || @name
      @ssh_ip = config[:legacy_machines][name][:ssh_ip]
      @ipv4_address = config[:legacy_machines][name][:ipv4_address]
    end

    def reachable_to?(vm, options = {})
      address = vm.__send__(options[:via] || :ipv4_address)
      options = to_ssh_option_string(
        "StrictHostKeyChecking" => "no",
        "UserKnownHostsFile" => "/dev/null",
        "LogLevel" => "ERROR",
        "ConnectTimeout" => options[:timeout] || 2
      )
      ret = ssh(ssh_ip, "ssh #{options} #{address} hostname", {})
      ret[:stdout].chomp == vm.hostname.to_s
    end
  end
end
