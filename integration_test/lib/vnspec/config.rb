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
      aggregate_logs: true,
      # Can be :before or :after to start VNA before or after
      # all entries in the OpenVNet database have been made.
      # Setting it to :both will cause both cases to be tested.
      vna_start_time: :both
    }

    class << self
      def config
        unless @config
          env = ENV["VNSPEC_ENV"] || "default"
          release_version = ENV['RELEASE_VERSION']
          @config = DEFAULT_CONFIG.dup
          @config[:env] = env
          @config[:release_version] = release_version
          ["base", env].each do |n|
            file = File.expand_path("../../config/#{n}.yml", File.dirname(__FILE__))
            @config.merge!(YAML.load_file(file).symbolize_keys)
          end
        end

        if vna_start_time = ENV['VNA_START_TIME']
          valid = ['before', 'after', 'both']
          if !valid.member?(vna_start_time)
            raise "Invalid VNA start time: '#{vna_start_time}'. Valid start times are: #{valid}"
          end

          @config[:vna_start_time] = vna_start_time.to_sym
        end

        @config
      end
    end

    def config
      Config.config
    end
  end
end
