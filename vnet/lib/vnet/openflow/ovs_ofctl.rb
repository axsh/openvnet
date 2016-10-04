module Vnet::Openflow

  class OvsOfctl
    include Celluloid::Logger

    attr_accessor :ovs_ofctl
    attr_accessor :ovs_vsctl
    attr_accessor :verbose
    attr_accessor :switch_name

    def initialize(datapath_id)
      @dpid = datapath_id
      @dpid_s = "0x%016x" % @dpid

      conf = Vnet::Configurations::Vna.conf

      @ovs_ofctl = 'ovs-ofctl -O OpenFlow13'
      @ovs_ofctl_10 = 'ovs-ofctl -O OpenFlow10'
      @ovs_vsctl = 'ovs-vsctl'

      @ovsdb = conf.ovsdb
      @ovs_vsctl += " --db=#{@ovsdb}" if @ovsdb

      @switch_name = conf.switch || get_bridge_name(datapath_id)

      @verbose = false

      validate_command
    end

    def validate_command
      if @switch_name.empty?
        raise "Unable to find a switch with datapath ID #{@dpid_s}.\n"\
              "Are the ovsdb settings in vna.conf correct?: '#{@ovsdb}'"
      end

      `#{@ovs_ofctl} show #{@switch_name}`
      raise "Unable to connect to switch #{@switch_name}" if $?.exitstatus != 0
    end

    def get_bridge_name(datapath_id)
      command = "#{@ovs_vsctl} --no-heading -- --columns=name find bridge datapath_id=%016x" % datapath_id
      debug log_format('get bridge name', command) if verbose

      `#{command}`.gsub(/"/, "").strip
    end

    def add_flow(flow)
      command = "#{@ovs_ofctl} add-flow #{switch_name} #{flow.match_to_s},actions=#{flow.actions_to_s}"
      result = system(command)

      debug log_format("'#{command}' => #{result}") if verbose
    end

    def add_ovs_flow(flow_str)
      command = "#{@ovs_ofctl} add-flow #{switch_name} \'#{flow_str}\'"
      result = system(command)

      debug log_format("'#{command}' => #{result}") if verbose
    end

    def add_ovs_10_flow(flow_str)
      command = "#{@ovs_ofctl_10} add-flow #{switch_name} \'#{flow_str}\'"
      result = system(command)

      debug log_format("'#{command}' => #{result}") if verbose
    end

    def add_flows(flows)
      recmds = []

      eos = "__EOS_ovs_ofctl___"
      recmds << "#{@ovs_ofctl} add-flow #{switch_name} - <<'#{eos}'"
      flows.each { |flow|
        full_flow = "#{flow.match_to_s},actions=#{flow.actions_to_s}"
        debug log_format("ovs-ofctl add-flow #{switch_name} #{full_flow}") if verbose
        recmds << full_flow
      }
      recmds << "#{eos}"

      debug log_format('applying flow(s)', "#{recmds.size - 2}") if verbose
      system(recmds.join("\n"))
    end

    def del_flows(flows)
      recmds = []

      eos = "__EOS_ovs_ofctl___"
      recmds << "#{@ovs_ofctl} del-flows #{switch_name} - <<'#{eos}'"
      flows.each { |flow|
        full_flow = "#{flow.match_sparse_to_s}"
        debug log_format("ovs-ofctl del-flow #{switch_name} #{full_flow}") if verbose
        recmds << full_flow
      }
      recmds << "#{eos}"

      debug log_format('removing flow(s)', "#{recmds.size - 2}") if verbose
      system(recmds.join("\n"))
    end

    def del_cookie(cookie)
      command = "#{@ovs_ofctl} del-flows #{switch_name} cookie=0x%x/-1" % cookie
      result = system(command)

      debug log_format("'#{command}' => #{result}") if verbose
    end

    def mod_port(port_no, action)
      debug log_format('modifying', "port_number:#{port_no} action:#{action}")

      arg = case action
            when :forward, :down, :flood, :stp, :receive, :up
              action.to_s
            when :no_flood then 'no-flood'
            when :no_stp then 'no-stp'
            when :no_receive then 'no-receive'
            end

      port_no = get_bridge_name(@dpid) if port_no == Controller::OFPP_LOCAL

      system("#{@ovs_ofctl_10} mod-port #{switch_name} #{port_no} #{arg}")
    end

    def add_tunnel(tunnel_name, params = {})
      debug log_format('create tunnel', "#{tunnel_name}")

      command = "#{@ovs_vsctl} --may-exist add-port #{switch_name} #{tunnel_name} -- set interface #{tunnel_name} type=gre options:in_key=flow options:out_key=flow"
      command << " options:remote_ip=#{params[:remote_ip]}" if params[:remote_ip]
      command << " options:local_ip=#{params[:local_ip]}" if params[:local_ip]

      debug command if verbose

      system(command)
    end

    def delete_tunnel(tunnel_name)
      debug log_format('delete tunnel', "#{tunnel_name}")

      command = "#{@ovs_vsctl} del-port #{switch_name} #{tunnel_name}"
      debug command if verbose
      system(command)
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dpid_s} ovs-ofctl: #{message}" + (values ? " (#{values})" : '')
    end

  end

end
