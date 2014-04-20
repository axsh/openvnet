#!/usr/bin/env ruby
require 'optparse'
require 'fileutils'
require 'json'

class SshConfig
  def initialize(options)
    @options = options
    @base_dir = File.expand_path(File.dirname(__FILE__))
    @ssh_dir = "#{@base_dir}/share/ssh"
    @ssh_hosts = ssh_hosts
    @base_config = base_config
    @host_config_file = File.join(Dir.home, ".ssh/config")
    @vnet_config_file = "#{@ssh_dir}/vnet_config"
    @vm_config_file = "#{@ssh_dir}/vm_config"

    @str_begin = "### vnet vagrant config begin ###"
    @str_end = "### vnet vagrant config end ###"
    @regexp = /#{@str_begin}.*#{@str_end}/m
  end

  def create_authorized_keys
    %x(ssh-keygen -y -f #{@options[:identity_file]} > #{@ssh_dir}/authorized_keys)
  end

  def add_identify_file_to_agent
    %x(ssh-add #{@options[:identity_file]})
  end

  def base_config
    <<-EOS
UserKnownHostsFile /dev/null
StrictHostKeyChecking no
PasswordAuthentication no
LogLevel FATAL
ForwardAgent yes
    EOS
  end

  def ssh_hosts
    [].tap do |hosts|
      # vnet
      Dir.glob("#{@base_dir}/nodes/*.json") do |filename|
        name = filename.sub(%r!.*/nodes/(.*)\.json!, '\1')
        node = JSON.parse(File.read(filename))

        hosts << {
          name: name,
          hostname: node["vnet"]["interfaces"].first["target"],
        }
      end

      # vm
      Dir.glob("#{@base_dir}/data_bags/vms/*.json") do |filename|
        name = filename.sub(%r!.*/nodes/(.*)\.json!, '\1')
        vm = JSON.parse(File.read(filename))

        hosts << {
          name: vm["id"],
          hostname: vm["host"],
          port: vm["ssh_port"],
        }
      end
    end
  end

  def vnet_config
    File.open(@vnet_config_file, "w+") do |file|
      config = @base_config

      @ssh_hosts.sort_by { |h| h[:id] }.each do |host|
        config += <<-EOS

  Host #{host[:name]}
    HostName #{host[:hostname]}
    Port #{host[:port] || 22}
    User vagrant
        EOS
      end

      file.puts config
    end
  end

  def vm_config
    File.open(@vm_config_file, "w+") do |file|
      file.puts(@base_config)
    end
  end

  def host_config
    host_config = [].tap { |str|
      str << @str_begin
      @ssh_hosts.sort_by { |h| h[:name] }.each do |host|
        str << <<-EOS

  Host #{host[:name]}
    HostName #{host[:hostname]}
    Port #{host[:port] || 22}
    User vagrant
    IdentityFile #{@options[:identity_file]}
    IdentitiesOnly yes
    UserKnownHostsFile /dev/null
    StrictHostKeyChecking no
    PasswordAuthentication no
    LogLevel FATAL
    ForwardAgent yes
        EOS
      end
      str << @str_end
    }.join("\n")


    puts host_config

    unless @options[:assume_yes]
      print "overwrite ssh config?[Y/n]"

      gets.chomp.tap do |ans|
        exit 0 if !ans.empty? && ans !~ /^[Yy]/
      end
    end

    File.open(@host_config_file, "r+") do |file|
      body = file.read
      if body =~ @regexp
        body.sub!(@regexp, host_config)
        file.rewind
        file.puts body
        file.truncate(file.tell)
      else
        file.puts
        file.puts host_config
      end
    end
  end
end

default_options = {
  assume_yes: false,
  identity_file: File.join(Dir.home, ".vagrant.d/insecure_private_key")
}

options = default_options.dup

OptionParser.new.tap do |opt|
  opt.on("-y") {|v| options[:assume_yes] = true }
  opt.on("-i IDENTITY_FILE") {|v| options[:identity_file] = v }
  opt.parse!(ARGV)
end

ssh_config = SshConfig.new(options)
ssh_config.create_authorized_keys
ssh_config.add_identify_file_to_agent
ssh_config.vnet_config
ssh_config.vm_config
ssh_config.host_config
