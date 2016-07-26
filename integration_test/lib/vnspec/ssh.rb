# -*- coding: utf-8 -*-
module Vnspec
  module SSH
    class Response < Hash
      def initialize(hash)
        super().merge!(hash)
      end

      def success?
        self[:exit_code] == 0
      end
    end

    DEFAULT_OPTIONS = {
      user: "root",
      debug: false,
      exit_on_error: true,
      use_sudo: false,
      use_agent: false,
      timeout: 300,
      verbose: :fatal,
    }

    def ssh_options
      DEFAULT_OPTIONS.merge(config[:ssh_options] || {})
    end

    def ssh(host, command, options = {})
      options = ssh_options.merge(options)
      command = wrap_command(command, options)
      logger.info "[#{host}] #{command}"

      stdout = ""
      stderr = ""
      exit_code = nil
      exit_signal = nil

      ssh_command_options = {
        timeout: options[:timeout],
        verbose: options[:verbose]
      }

      Net::SSH.start(host, options[:user], ssh_command_options) do |ssh|
        ssh.open_channel do |channel|
          channel.exec(command) do |ch, success|
            abort "Failed to execute [#{host}] #{command}" unless success

            channel.on_data do |ch, data|
              print data.to_s if options[:debug]
              stdout += data.to_s
            end

            channel.on_extended_data do |ch, type, data|
              print data.to_s if options[:debug]
              stderr += data.to_s
            end

            channel.on_request("exit-status") { |ch, data| exit_code = data.read_long }
            channel.on_request("exit-signal") { |ch, data| exit_code = data.read_long }
          end
        end

        ssh.loop
      end

      Response.new({stdout: stdout, stderr: stderr, exit_code: exit_code, exit_signal: exit_signal})
    end

    def multi_ssh(hosts, *commands)
      hosts = [hosts].flatten
      options = commands.last.is_a?(Hash) ? commands.pop : {}
      options = ssh_options.merge(options)
      Net::SSH::Multi.start do |session|
        hosts.each do |host|
          session.use(host, user: options[:user])
        end
        commands.each do |command|
          command = wrap_command(command, options)
          hosts.each do |host|
            logger.info "[#{host}] #{command}"
          end
          channel = session.exec(command)
          channel.wait
          unless channel.all? { |c| c[:exit_status] == 0 }
            return false if options[:exit_on_error]
          end
        end
      end
      return true
    end

    def scp(upload_or_download, host, local, remote)
      case upload_or_download.to_sym
      when :upload
        Net::SCP.download!(host, ssh_options[:user], local, remotel)
      when :download
        Net::SCP.download!(host, ssh_options[:user], remote, local)
      end
    end

    def to_ssh_option_string(options = {})
      options.map{|k,v| "-o #{k}=#{v}"}.join(" ")
    end

    def ssh_options_for_quiet_mode(options = {})
      {
        "StrictHostKeyChecking" => "no",
        "UserKnownHostsFile" => "/dev/null",
        "LogLevel" => "ERROR",
      }.merge(options)
    end

    def wrap_command(command, options)
      "bash -l -c '#{command}'".tap do |c|
        c.prepend "sudo " if options[:user] != "root" && options[:use_sudo]
      end
    end

    def start_ssh_agent
      logger.info "init ssh-agent"
      if ssh_options[:use_agent]
        key = ssh_options[:agent_key] || File.expand_path(File.join("../../vagrant/share/ssh/vnet_private_key"), File.dirname(__FILE__))
        system("eval $(ssh-agent)")
        system("ssh-add #{key}")
      end
    end
  end
end
