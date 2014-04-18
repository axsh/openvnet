# -*- coding: utf-8 -*-
require 'resolv'
require 'shellwords'

module Vnspec
  class VM
    class << self
      include SSH
      include Config
      include Logger

      def setup
        all.each do |vm|
          vm.vm_config[:interfaces].each do |interface_config|
            vm.interfaces << Models::Interface.find(interface_config[:uuid])
          end

          # Disabled as edge should always use a proper virtual network.
          # config[:legacy_networks].each do |k,v|
          #   ssh(vm.host_ip, "ssh #{vm.ssh_ip} route add -net #{v[:ipv4]}/#{v[:prefix]} dev eth0", {})
          # end
        end
      end

      def find(name)
        all.find{|vm| vm.name == name.to_sym}
      end
      alias :[] :find

      def all
        vm_class =
          case config[:vm_type].to_s
          when "docker"
            Docker
          when "kvm"
            KVM
          else
            Base
          end

        @vms ||= config[:vms].keys.map{|n| vm_class.new(n)}
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
            sleep(1)
            VM[name].__send__("start#{command}")
          end
        end)
      end

      private
      def _exec(command)
        all.peach(&command.to_sym)
      end
    end

    class Base
      include Config
      include SSH
      include Logger

      UDP_OUTPUT_DIR="/tmp"

      attr_reader :name, :hostname, :host_ip, :ssh_ip, :ssh_port, :interfaces, :vm_config
      def initialize(name)
        @vm_config = config[:vms][name.to_sym].dup
        @name = vm_config[:name].to_sym
        @hostname = vm_config[:hostname] || @name
        @ssh_ip = vm_config[:ssh_ip] || "127.0.0.1"
        @ssh_port = vm_config[:ssh_port] || 22
        @host_ip = config[:nodes][:vna][vm_config[:vna] - 1]

        @interfaces = []
        @open_udp_ports = {}
        @open_tcp_ports = {}
      end

      def start
        logger.info "start: #{name}"
        ssh_on_host("cd /images; ./run-#{name}", use_sudo: true)
      end

      def stop
        logger.info "stop: #{name}"
        ssh_on_host("cat /images/#{name}.pid | xargs kill -TERM", use_sudo: true)
      end

      def restart
        stop
        start
      end

      def start_network
        logger.info "start network: #{name}"
        _network_ctl(:start)
      end

      def stop_network
        logger.info "stop network: #{name}"
        _network_ctl(:stop)
      end

      def restart_network
        stop_network
        start_network
      end

      def ready?(timeout = 600)
        logger.info("waiting for ready: #{self.name}")
        expires_at = Time.now.to_i + timeout
        while ssh_on_guest("hostname", { "ConnectTimeout" => 2 })[:stdout].chomp != name.to_s
          if Time.now.to_i >= expires_at
            logger.info("#{self.name} is down")
            return false
          end
          sleep 3
        end
        logger.info("#{self.name} is ready")
        true
      end

      def reachable_to?(vm, options = {})
        via = options.delete(:via) || :ipv4_address
        hostname_for(vm.__send__(via), options) == vm.hostname.to_s
      end

      def resolvable?(name)
        stdout = ssh_on_guest("nslookup -timeout=1 -retry=0 #{name}")[:stdout]
        [
          %r(^\*\* server can't find),
          %r(^\*\*\* Can't find),
          %r(^;; connection timed out;),
        ].none? { |m| m.match(stdout) }
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
        cmd = "nohup nc -lu %s > %s 2> /dev/null < /dev/null & echo $!" %
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
        ssh_on_guest("killall nc", use_sudo: true)
      end

      def hostname_for(address, options = {})
        options = { "ConnectTimeout" => options[:timeout] || 2 }
        options = ssh_options_for_quiet_mode(options) if config[:ssh_quiet_mode]
        option_string = to_ssh_option_string(options)
        ssh_on_guest("ssh #{option_string} #{address} hostname")[:stdout].chomp
      end

      def ssh_on_guest(command, options = {})
        use_sudo = options.delete(:use_sudo)
        options = ssh_options_for_quiet_mode(options) if config[:ssh_quiet_mode]
        option_string = to_ssh_option_string(options)
        command = "sudo #{command}" if config[:vm_ssh_user] != "root" && use_sudo
        command = Shellwords.shellescape(command)
        command = "ssh #{option_string} #{config[:vm_ssh_user]}@#{ssh_ip} -p #{ssh_port} #{command}"
        ssh_on_host(command)
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

      def network
        network_uuid.split('-').last if network_uuid
      end

      def network_uuid
        # TODO
        interfaces.first.mac_leases.first.ip_leases.first.network_uuid rescue nil
      end

      def add_interface(options)
        if @interfaces.find{|i| i.uuid == options[:uuid] }
          raise "interface exists: #{options[:uuid]}"
        end
        interface_config = vm_config[:interfaces].find{|i| i[:uuid] == options[:uuid]}
        unless interface_config
          raise "vm interface not found: #{options[:uuid]}"
        end
        @interfaces << Models::Interface.create(options)
      end

      def remove_interface(uuid)
        @interfaces.find{|i| i.uuid == uuid}.tap do |interface|
          return unless interface
          @interfaces.delete(interface)
          interface.destroy
        end
      end

      def clear_arp_cache
        logger.debug("clear arp cahe: #{name}")
        ssh_on_guest("ip -s -s neigh flush all", use_sudo: true)
      end

      def add_security_group(uuid)
        @interfaces.each { |i| i.add_security_group(uuid) }
      end

      def remove_security_group(uuid)
        @interfaces.each { |i| i.remove_security_group(uuid) }
      end

      def install_package(name)
        ssh_on_guest("http_proxy=#{config[:vm_http_proxy]} yum install -y #{name}", use_sudo: true)
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
        vm_config[:interfaces].each do |i|
          ssh_on_guest("#{ifcmd} #{i[:name]}", use_sudo: true)
        end
      end
    end

    class KVM < Base
    end

    class Docker < Base
      def start
        logger.info "start: #{name}"
        if ssh_on_host("docker start #{name}").success?
          _start_network
        end
      end

      def stop
        logger.info "stop: #{name}"
        ssh_on_host("docker stop #{name}").success?
      end

      def restart
        stop
        start
      end

      def start_network
        restart
      end

      def _start_network
        vm_config[:interfaces].each do |interface|
          ip_address = if interface[:ipv4_address]
            "#{interface[:ip_v4address]}/#{interface[:mask] || 24}"
          else
            "dhcp"
          end

          command = [
            "#{config[:pipework_path]}/pipework",
            interface[:bridge],
            "-i", interface[:name],
            "-l", interface[:uuid],
            self.name,
            ip_address,
            interface[:mac_address],
          ]

          ssh_on_host(command.join(" "), use_sudo: true).success?.tap do
            update_dns
          end
        end
      end

      def stop_network
        # nothing to do
        true
      end

      def restart_network
        stop_network
        start_network
      end

      def ready?(timeout = 600)
        true
      end

      def ssh_on_guest(command, options = {})
        ssh(name.to_s, command, options)
      end

      def clear_arp_cache
        # TODO
        # does not work atm.
        #logger.debug("clear arp cahe: #{name}")
        #ssh_on_host("ip netns exec #{nspid} ip -s -s neigh flush all", use_sudo: true)
      end

      private
      def update_dns
        if ssh_on_host("[ -f /var/run/resolv.conf.#{name} ]").success?
            
          ssh_on_host("scp -P #{ssh_port} /var/run/resolv.conf.#{name} localhost:/tmp/resolv.dnsmasq.conf")
          ssh_on_guest("mv /tmp/resolv.dnsmasq.conf /etc/resolv.dnsmasq.conf", use_sudo: true)
          ssh_on_host("rm /var/run/resolv.conf.#{name}", use_sudo: true)
        end
        ssh_on_guest("service dnsmasq restart", use_sudo: true).success?
      end
    end
  end
end
