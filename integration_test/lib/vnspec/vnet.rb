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
          Parallel.each(config[:nodes][node_name.to_sym]) do |ip|
            ssh(ip, "initctl start vnet-#{node_name}", use_sudo: true)
            send(:wait_for, node_name)
          end
        else
          %w(vnmgr vna webapi).each do |n|
            start(n)
          end
        end
      end

      def stop(node_name = nil)
        if node_name
          Parallel.each(config[:nodes][node_name.to_sym]) do |ip|
            ssh(ip, "initctl stop vnet-#{node_name}", use_sudo: true)
          end
          rotate_log(node_name)
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
          multi_ssh(hosts, "cd #{File.join(config[:vnet_path], dir)}; bundle #{command.join(' ')};")
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

      def dump_logs(vna_index = nil)
        return unless config[:dump_flows]

        dump_header("dump_logs: vnmgr")
        output = ssh(config[:nodes][:vnmgr].first, "cat /var/log/openvnet/vnmgr.log", debug: false)
        logger.info output[:stdout]
        dump_footer

        dump_header("dump_logs: webapi")
        output = ssh(config[:nodes][:vnmgr].first, "cat /var/log/openvnet/webapi.log", debug: false)
        logger.info output[:stdout]
        dump_footer

        config[:nodes][:vna].each_with_index { |ip, i|
          next if vna_index && vna_index.to_i != i + 1
          dump_header("dump_logs: vna#{i + 1}")
          output = ssh(ip, "cat /var/log/openvnet/vna.log", debug: false)
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
        return false
      end

      def wait_for_vna
        sleep(config[:vna_waittime])
      end

      def aggregate_logs(job_id, name)
        return unless config[:aggregate_logs]
        @job_id = job_id

        yield.tap do
          env_dir = "#{Vnspec::ROOT}/log/#{config[:env]}"
          job_dir = "#{env_dir}/#{@job_id}"
          dst_dir = "#{job_dir}/#{name}"
          FileUtils.mkdir_p(dst_dir)
          config[:nodes].each do |node_name, ips|
            ips.each_with_index do |ip, i|
              src = logfile_for(node_name)
              dst = "#{dst_dir}/#{node_name}"
              dst += (i + 1).to_s if node_name == :vna
              dst += ".log"
              scp(:download, ip, dst, src)
            end
          end
          FileUtils.rm_f("#{env_dir}/current")
          File.symlink(job_dir, "#{env_dir}/current")
        end
      end

      private

      def rotate_log(node_name)
        return unless config[:aggregate_logs]
        return unless @job_id

        Parallel.each(config[:nodes][node_name.to_sym]) do |ip|
          logfile = logfile_for(node_name)
          timestamp = "#{Time.now.strftime("%Y%m%d%H%M%S%L")}"
          rotated_logfile = "#{logfile}.#{timestamp}"

          ssh(ip, "cp #{logfile} #{rotated_logfile}", use_sudo: true)
          ssh(ip, "gzip #{rotated_logfile}", use_sudo: true)

          ssh(ip, "truncate --size 0 #{logfile}", use_sudo: true)
        end
      end

      def logfile_for(node_name)
        File.join(config[:vnet_log_directory], "#{node_name}.log")
      end

      # Move logging stuff to a module.
      def dump_header(msg)
        logger.info "#" * 50
        logger.info "# #{msg}"
        logger.info "#" * 50
      end

      def dump_footer(msg = "")
        logger.info
        logger.info
      end

    end
  end
end
