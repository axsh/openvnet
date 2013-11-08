# -*- coding: utf-8 -*-
module Vnspec
  class Vnet
    class << self
      include SSH
      include Logger
      include Config

      def start(node_name = nil)
        if node_name
          config[:nodes][node_name.to_sym].peach do |ip|
            ssh(ip, "initctl start vnet-#{node_name.to_s}")
          end
        else
          %w(vnmgr vna webapi).each do |n|
            start(n)
          end
        end
      end

      def stop(node_name = nil)
        if node_name
          config[:nodes][node_name.to_sym].peach do |ip|
            ssh(ip, "initctl stop vnet-#{node_name.to_s}")
          end
        else
          %w(webapi vna vnmgr).each do |n|
            stop(n)
          end
        end
      end

      def restart(node_name = nil)
        stop(node_name)
        start(node_name)
      end

      def update(branch = nil)
        branch ||= config[:vnet_branch]
        case config[:update_vnet_via].to_sym
        when :rpm
          multi_ssh(config[:nodes][:vna],
            "yum clean metadata --disablerepo=* --enablerepo=wakame-vnet*",
            "yum update -y      --disablerepo=* --enablerepo=wakame-vnet*"
          )
        when :git
          multi_ssh(config[:nodes][:vna],
            "cd #{config[:vnet_path]}; git fetch --prune origin && git fetch --tags origin && git reset --hard origin/#{branch} && git clean -f -d && git checkout #{branch};",
            "bash -l -c 'cd #{File.join(config[:vnet_path], "vnet")}; bundle install --path vendor/bundle;'",
            "bash -l -c 'cd #{File.join(config[:vnet_path], "vnctl")}; bundle install --path vendor/bundle;'")
        end
      end

      def delete_tunnels(brige_name = "br0")
        multi_ssh(config[:nodes][:vna], "ovs-vsctl list-ports #{brige_name} | egrep '^t-' | xargs -n1 ovs-vsctl del-port #{brige_name}", exit_on_error: false)
      end

      def add_normal_flow(brige_name = "br0")
        multi_ssh(config[:nodes][:vna], "ovs-ofctl add-flow #{brige_name} priority=100,actions=NORMAL")
      end

      def reset_db
        multi_ssh(config[:nodes][:vnmgr], "bash -l -c 'cd /opt/axsh/wakame-vnet/vnet; bundle exec rake db:reset'")
      end

      def dump_flows
        config[:nodes][:vna].each_with_index do |ip, i|
          logger.info "#" * 50
          logger.info "# dump_flows: vna#{i + 1}"
          logger.info "#" * 50
          ofctl_output = ssh(ip, "ovs-ofctl -O OpenFlow13 dump-flows br0", debug: false)
          vnflows_output = %x(echo "#{ofctl_output.chomp}" | #{config[:vnflows_cmd]})
          logger.info vnflows_output
          logger.info
        end
      end
    end
  end
end
