# -*- coding: utf-8 -*-
module Vnspec
  class Vnet
    class << self
      include SSH
      include Logger
      include Config

      def hosts
        config[:nodes].values.flatten.uniq
      end

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
            "yum clean metadata --disablerepo=* --enablerepo=openvnet*",
            "yum update -y      --disablerepo=* --enablerepo=openvnet*"
          )
        when :git
          multi_ssh(config[:nodes][:vna],
            "cd #{config[:vnet_path]}; git fetch --prune origin; git fetch --tags origin; git clean -f -d; git rev-parse #{branch} | xargs git reset --hard; git checkout #{branch};",
            "bash -l -c 'cd #{File.join(config[:vnet_path], "vnet")}; bundle install --path vendor/bundle;'",
            "bash -l -c 'cd #{File.join(config[:vnet_path], "vnctl")}; bundle install --path vendor/bundle;'")
        end
      end

      def downgrade
        # only support rpm
        case config[:update_vnet_via].to_sym
        when :rpm
          multi_ssh(config[:nodes][:vna],
            "yum clean metadata --disablerepo=* --enablerepo=openvnet*",
            "yum downgrade -y --disablerepo=* --enablerepo=openvnet* openvnet*"
          )
        end
      end

      def delete_tunnels(brige_name = "br0")
        multi_ssh(config[:nodes][:vna], "ovs-vsctl list-ports #{brige_name} | egrep '^t-' | xargs -n1 ovs-vsctl del-port #{brige_name}", exit_on_error: false)
      end

      def add_normal_flow(brige_name = "br0")
        multi_ssh(config[:nodes][:vna], "ovs-ofctl add-flow #{brige_name} priority=100,actions=NORMAL")
      end

      def reset_db
        multi_ssh(config[:nodes][:vnmgr], "cd #{config[:vnet_path]}/vnet; bundle exec rake db:reset")
      end

      def dump_flows(vna_index = nil)
        return unless config[:dump_flows]
        config[:nodes][:vna].each_with_index do |ip, i|
          next if vna_index && vna_index.to_i != i + 1
          logger.info "#" * 50
          logger.info "# dump_flows: vna#{i + 1}"
          logger.info "#" * 50
          output = ssh(ip, "cd #{config[:vnet_path]}/vnet; bundle exec bin/vnflows-monitor", debug: false)
          logger.info output[:stdout]
          logger.info
        end
      end

      def install_package(name)
        run_command_on_vna_nodes("yum install -y #{name}")
      end

      def install_proxy_server
        install_package("squid")
        run_command_on_vna_nodes("service squid start")
        run_command_on_vna_nodes("chkconfig squid on")
      end

      def run_command_on_vna_nodes(*args)
        multi_ssh(config[:nodes][:vna], args.join(" "))
      end
      alias_method :run_command, :run_command_on_vna_nodes

      def wait_for_webapi(retry_count = 10)
        health_check_url = "http://#{config[:webapi][:host]}:#{config[:webapi][:port]}/api/datapaths"
        retry_count.times do
          `curl -fsSkL #{health_check_url}`
          return true if $? == 0
          sleep 1
        end
        return false
      end
    end
  end
end
