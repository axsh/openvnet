# -*- coding: utf-8 -*-
module Vnspec
  class Invoker
    include SSH
    include Logger
    include Config

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
        statuses = config[:specs].map do |name|
          [name, run(name)]
        end

        logger.info("-" * 50)
        statuses.each do |name, status|
          logger.info("#{name}: #{status ? "success" : "failure"}")
        end
        logger.info("-" * 50)

        return statuses.all?{|n, s| s }
      end
      unless config[:specs].member?(name.to_s)
        logger.error("spec not found: #{name}")
        raise
      end
      setup(name)
      sleep(1)
      SPec.exec(name)
    end

    def setup(name = :all)
      unless VM.ready?(10)
        logger.error("vm not ready")
        raise
      end

      VM.stop_network
      Vnet.stop
      #add_normal_flow
      Vnet.delete_tunnels

      Vnet.reset_db

      Vnet.start(:vnmgr)
      Vnet.start(:webapi)

      sleep(3)
      Dataset.setup(name)

      Vnet.start(:vna)

      VM.start_network
      sleep(1)
      Vnet.dump_flows

      true
    end

    def install_ssh_keys
      key = File.open(File.expand_path("~/.ssh/id_rsa.pub")){|f| f.read }
      multi_ssh(vnet_hosts, "echo '#{key}' >> ~/.ssh/authorized_keys")
    end

    def vnet_hosts
      config[:nodes].values.flatten.uniq
    end
  end
end
