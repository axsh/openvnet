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
        logger.info ""

        all.each { |vm|
          if !vm.use_vm
            logger.info "vm.setup #{vm.name}: skipping"
            next
          end

          logger.info "vm.setup #{vm.name}: setting up"

          vm.vm_config[:interfaces].each { |interface_config|
            Models::Interface.find(interface_config[:uuid]).tap { |model|
              if model
                logger.info "vm.setup #{vm.name}: adding interface uuid:#{interface_config[:uuid]} model.uuid:#{model.uuid}"
                vm.interfaces << model
              else
                logger.info "vm.setup #{vm.name}: could not find interface uuid:#{interface_config[:uuid]}"
              end
            }
          }

          logger.info "vm.setup #{vm.name}: done"
        }

        start_network

        logger.info ""
      end

      def all
        @vms ||= config_all_vms
      end

      def find(name)
        all.find { |vm| vm.name == name.to_sym }
      end
      alias :[] :find

      def each
        all.each { |vm| yield vm }
      end

      def parallel_each(&block)
        Parallel.each(all, &block)
      end

      def parallel_all?(&block)
        result = true

        Parallel.each(all) { |item|
          success = false unless block.call(item)
        }
        result
      end

      def ready?(name = :all, timeout = 600)
        parallel_all? { |vm|
          vm.ready?(timeout)
        }.tap { |success|
          if success
            logger.info("all vms are ready")
          else
            logger.info("one or more vms are down")
          end
        }
      end

      def install_package(name)
        parallel_each { |vm|
          next unless vm.use_vm
          vm.install_package(name)
        }
      end

      %w(start stop start_network stop_network).each do |command|
        define_method(command, ->(name = :all) do
          logger.debug "vm.#{name}: #{command}"

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

      def disable_vm
        vms.each { |vm| vm.use_vm = false }
      end

      def disable_dhcp
        vms.each { |vm| vm.use_dhcp = false }
      end

      private

      def _exec(command)
        logger.debug "vm._exec: #{command}"
        parallel_each(&command.to_sym)
      end

      def config_all_vms
        vm_class =
          case config[:vm_type].to_s
          when "docker"
            Docker
          when "kvm"
            KVM
          else
            Base
          end

        config[:vms].keys.map { |n| vm_class.new(n) }
      end
    end

    class Base
      include Config
      include SSH
      include Logger

      UDP_OUTPUT_DIR="/tmp"

      attr_reader :name
      attr_reader :hostname
      attr_reader :host_ip
      attr_reader :ssh_ip
      attr_reader :ssh_port
      attr_reader :interfaces
      attr_reader :vm_config

      attr_accessor :use_dhcp
      attr_accessor :use_vm

      def initialize(name)
        @vm_config = config[:vms][name.to_sym].dup
        @name = vm_config[:name].to_sym
        @hostname = vm_config[:hostname] || @name
        @ssh_ip = vm_config[:ssh_ip] || "127.0.0.1"
        @ssh_port = vm_config[:ssh_port] || 22
        @host_ip = config[:nodes][:vna][vm_config[:vna] - 1]

        @interfaces = []

        @use_dhcp = true
        @use_vm = true

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
        return unless @use_vm

        logger.info "#{name}.start_network: starting"

        _network_ctl(@use_dhcp ? :start : :start_no_dhcp).tap { |result|
          if result.nil?
            logger.warn("#{name}.start_network: started network on '#{name}'")
          else
            logger.warn("#{name}.start_network: could not start a network (results:#{result.inspect})")
            dump_vm_status
          end
        }
      end

      def stop_network
        logger.info "#{name}.start_network: stopping"
        _network_ctl(:stop)
      end

      def restart_network
        stop_network
        start_network
      end

      def ready?(timeout = 600)
        if !@use_vm
          logger.info("vm not enabled: #{self.name}")
          return true
        end

        logger.info("waiting for ready: #{self.name}")

        expires_at = Time.now.to_i + timeout

        while Time.now.to_i < expires_at
          result = ssh_on_guest("hostname", { "ConnectTimeout" => 2 })

          # TODO: This could be improved to break with an error if the
          # name doesn't match.
          if result[:stdout].chomp == @name.to_s
            logger.info("#{self.name} is ready")

            # Uncomment to dump status of all vm's.
            #dump_vm_status

            return true
          end

          sleep 3
        end

        logger.info("#{self.name} is down")
        logger.warn("#{self.name} ssh response:#{result.inspect}")

        dump_vm_status
        false
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

      def able_to_ping?(vm, trial = 1)
        ssh_on_guest("ping -c #{trial} #{vm.ipv4_address}")[:exit_code] == 0
      end

      def able_to_send_udp?(vm, port)
        ssh_on_guest("nc -zu #{vm.ipv4_address} #{port}")
        vm.ssh_on_guest("cat #{UDP_OUTPUT_DIR}/#{port}")[:stdout] == "XXXXX"
      end

      def able_to_send_tcp?(vm, port)
        ssh_on_guest("nc -zw 3 #{vm.ipv4_address} #{port}")[:exit_code] == 0
      end

      # TODO: Move these to a separate module.
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
        options.merge("ConnectTimeout" => 2)
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
        # Check if the ipv4 address has already been set manually.
        return @static_ipv4_address if @static_ipv4_address

        begin
          ip = interfaces.first.mac_leases.first.ip_leases.first.ipv4_address
          # for compativility
          ip = IPAddress::IPv4.parse_u32(ip).to_s unless ip =~ Resolv::IPv4::Regex
          ip
        rescue NoMethodError
          nil
        end
      end

      def change_ipv4_address(new_address, new_prefix = 24)
        @static_ipv4_address = IPAddress::IPv4.new("#{new_address}/#{new_prefix}")

        _network_ctl(:flush)
        _network_ctl(:change_ip, @static_ipv4_address)
      end

      def route_default_via(via_address)
        _network_ctl(:route_default_via, IPAddress::IPv4.new(via_address))
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

          # Rename to allow tests to reuse the uuid.
          interface.rename(uuid, "#{uuid}old")
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

      def dump_vm_status
        logger.info "##################################################"
        logger.info "# dump_vm_status #{name}"
        logger.info "##################################################"

        # Replace with stuff from the vm itself.
        full_response_log(ssh_on_guest("route -n"))
        full_response_log(ssh_on_guest("ip addr list"))
        # full_response_log(ssh_on_host("ls -l /"))
        # full_response_log(ssh_on_host("ls -l /images"))

        logger.info ""
        logger.info ""
      end

      private

      def _network_ctl(command, params = nil)
        # TODO: Rename to :ifup and :ip_link_up, etc.
        ifcmd =
          case command
          when :start
            'ifup %s'
          when :start_no_dhcp
            'ip link set dev %s up'
          when :stop
            'ifdown %s'
          when :flush
            'ip addr flush %s'
          when :change_ip
            'ip addr add ' + params.to_string + ' dev %s'
          when :route_default_via
            'ip route add default via ' + params.to_s + ' dev %s'
          else
            raise "unknown command: #{command}"
          end

        failed_results = nil

        vm_config[:interfaces].each { |i|
          result = ssh_on_guest("#{ifcmd}" % i[:name], use_sudo: true)

          if !result.success?
            failed_results ||= []
            failed_results << result
          end
        }

        failed_results
      end

    end

    class KVM < Base
    end

    class Docker < Base
      def start(with_network = true)
        logger.info "start: #{name}"
        if ssh_on_host("docker start #{name}").success?
          start_network if with_network
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
        vm_config[:interfaces].each do |interface|
          # TODO: Add support for static address.

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
        stop
        start(false)
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
