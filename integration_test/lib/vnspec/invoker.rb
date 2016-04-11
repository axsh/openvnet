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

        statuses = specs.map do |name|
          [name, run(name)]
        end

        logger.info("-" * 50)
        statuses.each do |name, status|
          logger.info("#{name}: #{status ? "success" : "failure"}")
        end
        logger.info("-" * 50)

        return statuses.all?{|n, s| s }
      end

      Vnet.aggregate_logs(job_id, name) do
        setup(name)
        sleep(1)

        result = SPec.exec(name)

        if !result
          Vnet.dump_logs
          Vnet.dump_flows
        end

        result
      end
    end

    def setup(name = :all)
      unless VM.ready?(10)
        logger.error("vm not ready")
        raise
      end

      VM.stop_network
      Vnet.stop
      #Vnet.add_normal_flow
      Vnet.delete_tunnels

      Vnet.reset_db

      Vnet.start(:vnmgr)
      Vnet.start(:webapi)

      Dataset.setup(name)

      Vnet.start(:vna)

      VM.start_network

      true
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
