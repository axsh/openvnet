# -*- coding: utf-8 -*-

require "fileutils"

module Vnspec
  class Invoker
    include SSH
    include Logger
    include Config

    TMP_DIR = File.expand_path("../../../tmp", __FILE__)
    PID_FILE = File.join(TMP_DIR, "vnspec.pid")

    def invoke(*args)
      init
      lock { __send__(*args) }
    end

    def vm(command, name)
      VM.__send__(command, name)
    end

    def vnet(command, *args)
      Vnet.__send__(command, *args)
    end

    def dataset(name)
      Dataset.setup(name)
    end

    def spec(name)
      SPec.exec(name)
    end

    def run(name = :all)
      if name.to_sym == :all
        specs = config[:specs]
        specs += config[:specs_ext] if config[:specs_ext]
      end

      if config[:vna_start_time] == :both
        vna_start_times = [:before, :after]
      else
        vna_start_times = config[:vna_start_time]
      end

      statuses = {}

      final_result = true
      vna_start_times.each_with_index { |start_time, i|
        highlighted_log "Pass #{i +1} of #{vna_start_times.length}: VNA started #{start_time} running vnctl commands"

        statuses[start_time] = specs.map do |name|
          result = run_specs(name, start_time)
          final_result = false if !result

          [name, result]
        end
      }

      vna_start_times.each { |start_time|
        logger.info("-" * 50)
        logger.info("VNA started #{start_time} running vnctl commands")
        logger.info ""
        statuses[start_time].each do |name, status|
          logger.info("#{name}: #{status ? "success" : "failure"}")
        end
        logger.info("-" * 50)
        logger.info ""
      }

      final_result
    end

    def run_specs(name, vna_start_time = :after)
      highlighted_log "Running spec '#{name}'."

      unless VM.ready?(10)
        logger.error("vm not ready")
        raise
      end

      VM.stop_network
      Vnet.stop
      Vnet.delete_tunnels

      Vnet.reset_db

      Vnet.aggregate_logs(job_id, name) do
        Vnet.start(:vnmgr)
        Vnet.start(:webapi)

        if vna_start_time == :before
          Vnet.start(:vna)
          Dataset.setup(name)
        else
          Dataset.setup(name)
          Vnet.start(:vna)
        end

        sleep(1)

        result = SPec.exec(name)

        if !result
          Vnet.dump_logs
          Vnet.dump_flows
          Vnet.dump_database
        end

        result
      end
    end

    def install_ssh_keys
      key = File.open(File.expand_path("~/.ssh/id_rsa.pub")){|f| f.read }
      multi_ssh(Vnet.hosts, "echo '#{key}' >> ~/.ssh/authorized_keys")
    end

    private

    def lock(&block)
      FileUtils.mkdir_p(TMP_DIR)
      FileUtils.touch(PID_FILE)
      File.open(PID_FILE, "r+") do |file|
        pid = file.read.chomp!.to_i
        if !running_process?(pid) && file.flock(File::LOCK_EX | File::LOCK_NB)
          file.rewind
          file.puts($$)
        else
          logger.info("process(pid: #{pid}) still running")
          return false
        end
      end
      yield
    end

    def running_process?(pid)
      return false unless pid.to_i > 0
      begin
        Process.kill(0, pid)
      rescue Errno::ESRCH, Errno::EPERM
        return false
      end
      return true
    end

    def job_id
      @job_id ||= "#{Time.now.strftime("%Y%m%d%H%M%S")}"
    end

    def init
      start_ssh_agent
    end
  end
end
