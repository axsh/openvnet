module Vnet::Openflow

  class OvsOfctl
    include Celluloid::Logger

    attr_accessor :ovs_ofctl
    attr_accessor :ovs_vsctl
    attr_accessor :verbose
    attr_accessor :switch_name

    def initialize(datapath_id)
      # TODO: Make ovs_vsctl use a real config option.
      conf = Vnet::Configurations::Vna.conf
      # @ovs_ofctl = conf.ovs_ofctl_path
      # @ovs_vsctl = conf.ovs_vsctl_path
      @ovs_ofctl = 'ovs-ofctl -O OpenFlow13'
      @ovs_vsctl = 'ovs-vsctl'
      @switch_name = get_bridge_name(datapath_id)

      # @verbose = Dcmgr.conf.verbose_openflow
      @verbose = true
    end

    def get_bridge_name(datapath_id)
      command = "#{@ovs_vsctl} --no-heading -- --columns=name find bridge datapath_id=%016x" % datapath_id
      p command if verbose
      /^"(.*)"/.match(`#{command}`)[1]
    end

    def add_flow(flow)
      command = "#{@ovs_ofctl} add-flow #{switch_name} #{flow.match_to_s},actions=#{flow.actions_to_s}"
      debug "'#{command}' => #{system(command)}."
    end

    def add_ovs_flow(flow_str)
      command = "#{@ovs_ofctl} add-flow #{switch_name} #{flow_str}"
      debug "'#{command}' => #{system(command)}"
    end

    def add_flows(flows)
      recmds = []

      eos = "__EOS_ovs_ofctl___"
      recmds << "#{@ovs_ofctl} add-flow #{switch_name} - <<'#{eos}'"
      flows.each { |flow|
        full_flow = "#{flow.match_to_s},actions=#{flow.actions_to_s}"
        debug "ovs-ofctl add-flow #{switch_name} #{full_flow}" if verbose
        recmds << full_flow
      }
      recmds << "#{eos}"

      p("applying flow(s): #{recmds.size - 2}")
      #system(recmds.join("\n"))
      `#{recmds.join("\n")}`
    end

    def del_flows(flows)
      recmds = []

      eos = "__EOS_ovs_ofctl___"
      recmds << "#{@ovs_ofctl} del-flows #{switch_name} - <<'#{eos}'"
      flows.each { |flow|
        full_flow = "#{flow.match_sparse_to_s}"
        debug "ovs-ofctl del-flow #{switch_name} #{full_flow}" if verbose
        recmds << full_flow
      }
      recmds << "#{eos}"

      p("removing flow(s): #{recmds.size - 2}")
      system(recmds.join("\n"))
    end

    def del_cookie(cookie)
      command = "#{@ovs_ofctl} del-flows #{switch_name} cookie=0x%x/-1" % cookie
      debug "'#{command}' => #{system(command)}"
    end

    def add_tunnel(tunnel_name, remote_ip)
      system("#{@ovs_vsctl} --may-exist add-port #{switch_name} #{tunnel_name} -- set interface #{tunnel_name} type=gre options:remote_ip=#{remote_ip} options:in_key=flow options:out_key=flow")
    end

  end

end
