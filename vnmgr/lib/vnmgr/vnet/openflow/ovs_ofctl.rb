module Vnmgr::VNet::Openflow

  class OvsOfctl
    attr_accessor :ovs_ofctl
    attr_accessor :ovs_vsctl
    attr_accessor :verbose
    attr_accessor :switch_name

    def initialize(switch_name = nil)
      # TODO: Make ovs_vsctl use a real config option.
      # @ovs_ofctl = Dcmgr.conf.ovs_ofctl_path
      # @ovs_vsctl = Dcmgr.conf.ovs_ofctl_path.dup
      # @ovs_vsctl[/ovs-ofctl/] = 'ovs-vsctl'
      @ovs_ofctl = 'ovs-ofctl -O OpenFlow13'
      @ovs_vsctl = 'ovs-vsctl'
      @switch_name = switch_name

      # @verbose = Dcmgr.conf.verbose_openflow
      @verbose = true
    end

    def get_bridge_name(datapath_id)
      command = "#{@ovs_vsctl} --no-heading -- --columns=name find bridge datapath_id=%016x" % datapath_id
      p command if verbose == true
      /^"(.*)"/.match(`#{command}`)[1]
    end

    def add_flow(flow)
      command = "#{@ovs_ofctl} add-flow #{switch_name} #{flow.match_to_s},actions=#{flow.actions_to_s}"
      p "'#{command}' => #{system(command)}."
    end

    def add_flows(flows)
      recmds = []

      eos = "__EOS_ovs_ofctl___"
      recmds << "#{@ovs_ofctl} add-flow #{switch_name} - <<'#{eos}'"
      flows.each { |flow|
        full_flow = "#{flow.match_to_s},actions=#{flow.actions_to_s}"
        p "ovs-ofctl add-flow #{switch_name} #{full_flow}" if verbose == true
        recmds << full_flow
      }
      recmds << "#{eos}"

      p("applying flow(s): #{recmds.size - 2}")
      system(recmds.join("\n"))
    end

    def del_flows(flows)
      recmds = []

      eos = "__EOS_ovs_ofctl___"
      recmds << "#{@ovs_ofctl} del-flows #{switch_name} - <<'#{eos}'"
      flows.each { |flow|
        full_flow = "#{flow.match_sparse_to_s}"
        p "ovs-ofctl del-flow #{switch_name} #{full_flow}" if verbose == true
        recmds << full_flow
      }
      recmds << "#{eos}"

      p("removing flow(s): #{recmds.size - 2}")
      system(recmds.join("\n"))
    end

    def del_cookie(cookie)
      command = "#{@ovs_ofctl} del-flows #{switch_name} cookie=0x%x/-1" % cookie
      p "'#{command}' => #{system(command)}"
    end

    def add_gre_tunnel(tunnel_name, remote_ip, key)
      system("#{@ovs_vsctl} add-port #{switch_name} #{tunnel_name} -- set interface #{tunnel_name} type=gre options:remote_ip=#{remote_ip} options:key=#{key}")
    end

  end

end
