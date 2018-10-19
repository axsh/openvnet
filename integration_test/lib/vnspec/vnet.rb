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

      def manage_node(ip, operation, node_name)
        service_cmd = case config[:release_version]
                      when "el7"     then "systemctl"
                      when "el6",nil then "initctl"
                      end
        ssh(ip, "#{service_cmd} #{operation} vnet-#{node_name.to_s.tr('_', '-')}", use_sudo: true)
      end

      def start(node_name)
        Parallel.each(config[:nodes][node_name.to_sym]) do |ip|
          manage_node(ip, "start", node_name)
          send(:wait_for, node_name)
        end
      end

      def stop(node_name)
        Parallel.each(config[:nodes][node_name.to_sym]) do |ip|
          manage_node(ip, "stop", node_name)
        end
        rotate_log(node_name)
      end

      def update(branch = nil)
        branch ||= config[:vnet_branch]
        case config[:update_vnet_via].to_sym
        when :rpm
          multi_ssh(hosts,
            "yum clean metadata --disablerepo=* --enablerepo=openvnet*",
            "yum update -y      --disablerepo=* --enablerepo=openvnet*",
            use_sudo: true
          )
        when :git
          multi_ssh(hosts,
            "cd #{config[:vnet_path]}; git fetch --prune origin; git fetch --tags origin; git clean -f -d; git rev-parse origin/#{branch} | xargs git reset --hard; git checkout #{branch};"
          )
        when :rsync
          # do nothing
        end
      end

      def bundle(*command)
        hosts = case config[:update_vnet_via].to_sym
        when :rpm
          raise NotImplementedError.new("please update gems via rpm.")
        when :git, :rsync
          self.hosts
        end

        %w(vnet vnctl).each do |dir|
          multi_ssh(hosts, "cd #{File.join(config[:vnet_path], dir)}; [ -f /etc/openvnet/vnctl-ruby ] && . /etc/openvnet/vnctl-ruby; bundle #{command.join(' ')};")
        end
      end

      def bundle_install
        bundle("install")
      end

      def downgrade
        case config[:update_vnet_via].to_sym
        when :rpm
          multi_ssh(hosts,
            "yum clean metadata --disablerepo=* --enablerepo=openvnet*",
            "yum downgrade -y --disablerepo=* --enablerepo=openvnet* openvnet*",
            use_sudo: true
          )
        when :git, :rsync
          raise NotImplementedError.new("please downgrade yourself!")
        end
      end

      def delete_tunnels(brige_name = "br0")
        multi_ssh(
          config[:nodes][:vna],
          "ovs-vsctl list-ports #{brige_name} | egrep '^t-' | xargs -n1 ovs-vsctl del-port #{brige_name}",
          exit_on_error: false,
          use_sudo: true
        )
      end

      def add_normal_flow(brige_name = "br0")
        multi_ssh(
          config[:nodes][:vna],
          "ovs-ofctl add-flow #{brige_name} priority=100,actions=NORMAL",
          use_sudo: true
        )
      end

      def reset_db
        multi_ssh(config[:nodes][:vnmgr], "cd #{config[:vnet_path]}/vnet; [ -f /etc/openvnet/vnctl-ruby ] && . /etc/openvnet/vnctl-ruby; bundle exec rake db:reset")
      end

      # TODO: Move logging stuff to module.
      def fetch_log_output(service)
        # vnmgr still outputs to the original logfile
        (config[:release_version] != "el7" || service == "vnmgr" ? "cat /var/log/openvnet/%s.log" : "journalctl -u vnet-%s") % service.to_s.tr('_', '-')
      end

      def dump_flows(vna_index = nil)
        return unless config[:dump_flows]

        config[:nodes][:vna].each_with_index do |ip, i|
          next if vna_index && vna_index.to_i != i + 1
          dump_header("dump_flows: vna#{i + 1}")
          output = ssh(ip, "cd #{config[:vnet_path]}/vnet; [ -f /etc/openvnet/vnctl-ruby ] && . /etc/openvnet/vnctl-ruby; bundle exec bin/vnflows-monitor", debug: false)
          logger.info output[:stdout]
          dump_footer
        end
      end

      def dump_logs(vna_index = nil)
        return unless config[:dump_flows]

        dump_single_node(:vnmgr)
        dump_single_node(:webapi)

        config[:nodes][:vna].each_with_index { |ip, i|
          next if vna_index && vna_index.to_i != i + 1
          dump_header("dump_logs: vna#{i + 1}")
          output = ssh(ip, fetch_log_output("vna"), debug: false)
          logger.info output[:stdout]
          dump_footer
        }

        config[:nodes][:vna].each_with_index { |ip, i|
          next if vna_index && vna_index.to_i != i + 1

          dump_header("dump_node_status #{ip}")
          full_response_log(ssh(ip, "route -n"))
          full_response_log(ssh(ip, "ip addr list"))
          full_response_log(ssh(ip, "ls -l /"))
          full_response_log(ssh(ip, "ls -l /images"))
          dump_footer
        }

        Vnspec::VM.each { |vm|
          vm.use_vm && vm.dump_vm_status
        }

        ENV['REDIS_MONITOR_LOGS'].to_s == '1' && dump_single_node(:redis_monitor)
      end

      def dump_single_node(node_name)
        dump_header("dump_logs: #{node_name}")
        output = ssh(config[:nodes][node_name.to_sym].first, fetch_log_output(node_name), debug: false)
        logger.info output[:stdout]
        dump_footer
      end

      def dump_database
        return unless config[:dump_flows]

        dump_header("dump_database: vnmgr")

        [ :networks,
          :segments,
          :route_links,

          :interfaces,

          :datapaths,
          :datapath_networks,
          :datapath_segments,
          :datapath_route_links,

          :topologies,
          :topology_datapaths,
          :topology_networks,
          :topology_segments,
          :topology_route_links,

          :tunnels,

          :active_interfaces,
          :active_ports,
          :active_networks,
          :active_segments,
          :active_route_links,

        ].each { |table_name|
          ssh(config[:nodes][:vnmgr].first, "mysql -te select\\ *\\ from\\ #{table_name}\\; vnet", debug: false).tap { |output|
            logger.info output[:stdout]
          }
        }

        dump_footer
      end

      def install_package(name)
        run_command_on_vna_nodes("yum install -y #{name}", use_sudo: true)
      end

      def install_proxy_server
        install_package("squid")
        run_command_on_vna_nodes("service squid start", use_sudo: true)
        run_command_on_vna_nodes("chkconfig squid on", use_sudo: true)
      end

      def run_command_on_vna_nodes(*args)
        multi_ssh(config[:nodes][:vna], *args)
      end
      alias_method :run_command, :run_command_on_vna_nodes

      def wait_for(name)
        logger.info "waiting for #{name}..."
        method_name = "wait_for_#{name}"
        send method_name if respond_to?(method_name)
      end

      def wait_for_webapi
        retry_count = 20
        health_check_url = "http://#{config[:webapi][:host]}:#{config[:webapi][:port]}/api/datapaths"

        retry_count.times do
          system("curl -fsSkL #{health_check_url}")
          return true if $? == 0
          sleep 1
        end

        dump_single_node(:webapi)

        return false
      end

      def wait_for_vna
        sleep(config[:vna_waittime])
      end

      def aggregate_logs(job_id, name)
        return unless config[:aggregate_logs]

        @job_id = job_id

        yield.tap do
          env_dir, job_dir, dst_dir = log_dirs(job_id, name)

          FileUtils.mkdir_p(dst_dir)

          config[:nodes].each { |node_name, ips|
            node_name == :redis_monitor && ENV['REDIS_MONITOR_LOGS'].to_s != '1' && next

            ips.each_with_index { |ip, i|
              src = logfile_for(node_name)
              dst = "#{dst_dir}/#{node_name.to_s.tr('_', '-')}"
              dst += (i + 1).to_s if node_name == :vna
              dst += ".log"

              logger.info "aggregating log: node_name:#{node_name} ip:#{ip} src:#{src.to_s} dst:#{dst.to_s}"

              scp(:download, ip, dst, src)
            }
          }

          FileUtils.rm_f("#{env_dir}/current")
          File.symlink(job_dir, "#{env_dir}/current")
        end
      end

      private

      def rotate_log(node_name)
        Parallel.each(config[:nodes][node_name.to_sym]) do |ip|
          logfile = logfile_for(node_name)

          if config[:aggregate_logs] && @job_id
            timestamp = "#{Time.now.strftime("%Y%m%d%H%M%S%L")}"
            rotated_logfile = "#{logfile}.#{timestamp}"

            ssh(ip, "cp #{logfile} #{rotated_logfile}", use_sudo: true)
            ssh(ip, "gzip #{rotated_logfile}", use_sudo: true)
          end

          ssh(ip, "truncate --size 0 #{logfile}", use_sudo: true)

          if config[:release_version] == "el7"
            ssh(ip, "sudo -u vnet-#{node_name.to_s.tr('_', '-')} journalctl --vacuum-time=1seconds vnet-#{node_name.to_s.tr('_', '-')}")
          end
        end
      end

      def log_dirs(job_id, name)
        env_dir = "#{Vnspec::ROOT}/log/#{config[:env]}"
        job_dir = "#{env_dir}/#{@job_id}"
        dst_dir = "#{job_dir}/#{name}"
        return env_dir, job_dir, dst_dir
      end

      def logfile_for(node_name)
        File.join(config[:vnet_log_directory], "#{node_name.to_s.tr('_', '-')}.log")
      end

    end
  end
end
