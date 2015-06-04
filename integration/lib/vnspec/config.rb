module Vnspec
  module Config
    DEFAULT_CONFIG = {
      vnet_path: "/opt/axsh/openvnet",
      vnet_branch: "master",
      vnet_log_directory: "/var/log/openvnet",
      update_vnet_via: "rsync",
      vm_ssh_user: "root",
      exit_on_error: true,
      test_ready_check_interval: 10,
      test_retry_count: 30,
      log_level: :info,
      vna_waittime: 0,
      ssh_quiet_mode: false,
      aggregate_logs: true
    }

    class << self
      def config
        unless @config
          env = ENV["VNSPEC_ENV"] || "default"
          @config = DEFAULT_CONFIG.dup
          @config[:env] = env
          ["base", env].each do |n|
            file = File.expand_path("../../config/#{n}.yml", File.dirname(__FILE__))
            @config.merge!(YAML.load_file(file).symbolize_keys)
          end
        end
        @config
      end
    end

    def config
      Config.config
    end
  end
end
