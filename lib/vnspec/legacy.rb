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
        config[:legacy].keys.map do |m|
          @@legacy_machines << self.new(m)
        end
      end

      def find(name)
        @@legacy_machines.find { |m| m.name == name }
      end
      alias :[] :find
    end

    attr_reader :name
    attr_reader :ip

    def initialize(name)
      @name = name.to_sym
      @ip = config[:legacy][name][:ssh_ip]
    end

    def reachable_to?(vm, timeout = 30)
      options = to_ssh_option_string(
        "StrictHostKeyChecking" => "no",
        "UserKnownHostsFile" => "/dev/null",
        "LogLevel" => "ERROR",
        "ConnectTimeout" => timeout
      )
      ret = ssh(ip, "ssh #{options} #{config[:ssh_user]}@#{vm.ipv4_address} hostname", {})
      ret == vm.name.to_s
    end
  end
end
