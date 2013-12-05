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

      Net::SSH.start(host, options[:user]) do |ssh|
        ssh.exec!(command).tap do |result|
          break unless result
          result.split(/\r[\n]?|\n/).map do |line|
            logger.info("[#{host}] #{line}") if options[:debug]
          end
        end
      end
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
