# -*- coding: utf-8 -*-
require 'resolv'

module Vnspec
  class VM
    UDP_OUTPUT_DIR="/tmp"

    include Config
    include SSH
    include Logger

    class << self
      include SSH
      include Config
      include Logger

      def setup
        all.each do |vm|
          vm.interfaces.each do |interface|
            API.request(:get, "interfaces/#{interface.uuid}") do |response|
              response["mac_leases"].each do |mac_lease|
                interface.mac_leases << Models::MacLease.new(uuid: mac_lease["uuid"], interface: interface,  mac_address: mac_lease["mac_address"]).tap do |m|
                  response["ip_leases"].select do |ip_lease|
                    # TODO use uuid instead of id
                    ip_lease["mac_lease_id"] == mac_lease["id"]
                  end.each do |ip_lease|
                    m.ip_leases << Models::IpLease.new(uuid: ip_lease["uuid"], mac_lease: m, ipv4_address: ip_lease["ipv4_address"], network_uuid: ip_lease["network_uuid"])
                  end
                end
              end
            end
          end

          config[:legacy_networks].each do |k,v|
            ssh(vm.host_ip, "ssh #{vm.ssh_ip} route add -net #{v[:ipv4]}/#{v[:prefix]} dev eth0", {})
          end
        end
      end

      def find(name)
        all.find{|vm| vm.name == name.to_sym}
      end
      alias :[] :find

      def all
        @vms ||= config[:vms].keys.map{|n| self.new(n)}
      end

      def each
        all.each{|vm| yield vm}
      end

      def peach
        all.peach{|vm| yield vm}
      end

      def ready?(name = :all, timeout = 600)
        success = true
        peach do |vm|
          success = false unless vm.ready?(timeout)
        end
        if success
          logger.info("all vms are ready")
        else
          logger.info("any vm is down")
        end
        success
      end

      def install_package(name)
        all.peach { |vm| vm.install_package(name) }
      end

      %w(start stop start_network stop_network).each do |command|
        define_method(command, ->(name = :all) do
          if name.to_sym == :all
            _exec(command)
          else
            VM[name].__send__(command)
          end
        end)
      end

      ["", "_network"].each do |command|
        define_method("restart#{command}", ->(name = :all) do
          if name.to_sym == :all
            _exec("stop#{command}")
            _exec("start#{command}")
          else
            VM[name].__send__("stop#{command}")
            VM[name].__send__("start#{command}")
          end
        end)
      end

      private
      def _exec(command)
        all.peach(&command.to_sym)
      end
    end

    attr_reader :name, :host_ip, :ssh_ip, :interfaces, :vm_config
    def initialize(name)
      @vm_config = config[:vms][name.to_sym].dup
      @name = vm_config[:name].to_sym
      @ssh_ip = vm_config[:ssh_ip]
      @host_ip = config[:nodes][:vna][vm_config[:vna] - 1]
      @interfaces = vm_config[:interfaces].map do |interface|
        Models::Interface.new(uuid: interface[:uuid], name: interface[:name])
      end

      @open_udp_ports = {}
      @open_tcp_ports = {}
    end

    def start
      ssh_on_host("cd /images; ./run-#{name}")
    end

    def stop
      ssh_on_host("cat /images/#{name}.pid | xargs kill -TERM")
    end

    def restart
      stop
      start
    end

    def start_network
      _network_ctl(:start)
    end

    def stop_network
      _network_ctl(:stop)
    end

    def restart_network
      stop_network
      start_network
    end

    def ready?(timeout = 600)
      logger.info("waiting for ready: #{self.name}")
      expires_at = Time.now.to_i + timeout
      while ssh_on_guest("hostname", {ConnectTimeout: 1}, {debug: true})[:stdout].chomp != name.to_s
        if Time.now.to_i >= expires_at
          logger.info("#{self.name} is down")
          return false
        end
        sleep 3
      end
      logger.info("#{self.name} is ready")
      true
    end

    def reachable_to?(vm, timeout = 2)
      hostname_for(vm.ipv4_address, timeout) == vm.name.to_s
    end

    def able_to_ping?(vm)
      ssh_on_guest("ping -c 1 #{vm.ipv4_address}")[:exit_code] == 0
    end

    def able_to_send_udp?(vm, port)
      ssh_on_guest("nc -zu #{vm.ipv4_address} #{port}")
      vm.ssh_on_guest("cat #{UDP_OUTPUT_DIR}/#{port}")[:stdout] == "XXXXX"
    end

    def able_to_send_tcp?(vm, port)
      ssh_on_guest("nc -zw 3 #{vm.ipv4_address} #{port}")[:exit_code] == 0
    end

    def udp_listen(port)
      cmd = "'nohup nc -lu %s > %s 2> /dev/null < /dev/null & echo $!'" %
        [port, "#{UDP_OUTPUT_DIR}/#{port}"]

      pid = ssh_on_guest(cmd)[:stdout].chomp
      @open_udp_ports[port] = pid
    end

    def udp_close(port)
      cmds = [
        "kill #{@open_udp_ports.delete(port)}",
        "rm -f #{UDP_OUTPUT_DIR}/#{port}"
      ]

      ssh_on_guest(cmds.join(";"))
    end

    def tcp_listen(port)
      cmd = "nohup nc -l %s > /dev/null 2> /dev/null < /dev/null & echo $!" %
        port

      pid = ssh_on_guest(cmd)[:stdout].chomp
      @open_tcp_ports[port] = pid
    end

    def tcp_close(port)
      ssh_on_guest("kill #{@open_tcp_ports.delete(port)}")
    end

    def close_all_listening_ports
      ssh_on_guest("killall nc")
    end

    def hostname_for(ip, timeout = 2)
      options = to_ssh_option_string(
        "StrictHostKeyChecking" => "no",
        "UserKnownHostsFile" => "/dev/null",
        "LogLevel" => "ERROR",
        "ConnectTimeout" => timeout
      )
      ssh_on_guest("ssh #{options} #{ip} hostname")[:stdout].chomp
    end

    def ssh_on_guest(command, options = {}, host_options = {})
      options = to_ssh_option_string(options)
      ssh_on_host("ssh #{options} #{config[:ssh_user]}@#{ssh_ip} #{command}", host_options)
    end

    def ssh_on_host(command, options = {})
      ssh(host_ip, command, options)
    end

    def ipv4_address
      begin
        ip = interfaces.first.mac_leases.first.ip_leases.first.ipv4_address
        # for compativility
        ip = IPAddress::IPv4.parse_u32(ip).to_s unless ip =~ Resolv::IPv4::Regex
        ip
      rescue NoMethodError
        nil
      end
    end

    def add_interface(options)
      if @interfaces.find{|i| i.uuid == options[:uuid] }
        raise "interface exists: #{options[:uuid]}"
      end
      interface_config = vm_config[:interfaces].find{|i| i[:uuid] == options[:uuid]}
      unless interface_config
        raise "vm interface not found: #{options[:uuid]}"
      end
      Models::Interface.create(options).tap do |interface|
        interface.name = interface_config[:name]
        @interfaces << interface
      end
    end

    def remove_interface(uuid)
      interface = @interfaces.find{|i| i.uuid == uuid}.tap do |interface|
        return unless interface
        @interfaces.delete(interface)
        interface.destroy
      end
    end

    def install_package(name)
      ssh_on_guest("http_proxy=#{config[:vm_http_proxy]} yum install -y #{name}")
    end

    private
    def _network_ctl(command)
      ifcmd =
        case command
        when :start
          "ifup"
        when :stop
          "ifdown"
        else
          raise "unknown command: #{command}"
        end
      interfaces.each do |interface|
        ssh_on_guest("#{ifcmd} #{interface.name}")
      end
    end
  end
end
