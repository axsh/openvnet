# -*- coding: utf-8 -*-
module Vnspec
  module SSH
    DEFAULT_OPTIONS = {
      user: "root",
      debug: true,
      exit_on_error: true,
    }

    def ssh_options
      DEFAULT_OPTIONS.merge(config[:ssh_options] || {})
    end

    def ssh(host, command, options = {})
      options = ssh_options.merge(options)
      logger.info "[#{host}] #{command}" if options[:debug]

      stdout = ""
      stderr = ""
      exit_code = nil
      exit_signal = nil

      Net::SSH.start(host, options[:user]) do |ssh|
        ssh.open_channel do |channel|
          channel.exec(command) do |ch, success|
            abort "Failed to execute [#{host}] #{command}" unless success

            channel.on_data { |ch, data| stdout += data.to_s }
            channel.on_extended_data { |ch, data| data; stderr += data.to_s }
            channel.on_request("exit-status") { |ch, data| exit_code = data.read_long }
            channel.on_request("exit-signal") { |ch, data| exit_code = data.read_long }
          end
        end
        ssh.loop
      end

      if options[:debug]
        stdout.split(/\r[\n]?|\n/).map do |line|
          logger.info("[#{host}] #{line}")
        end
      end

      {stdout: stdout, stderr: stderr, exit_code: exit_code, exit_signal: exit_signal}
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
          hosts.each do |host|
            logger.debug "[#{host}] #{command}" if options[:debug]
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

    def to_ssh_option_string(options = {})
      options.map{|k,v| "-o #{k}=#{v}"}.join(" ")
    end
  end
end
