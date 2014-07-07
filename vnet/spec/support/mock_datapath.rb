# -*- coding: utf-8 -*-

class MockOvsOfctl
  def initialize(datapath)
    @datapath = datapath
  end

  def mod_port(port_no, action)
  end

  def add_tunnel(tunnel_name, params)
    @dp_info.added_tunnels << params.merge(tunnel_name: tunnel_name)
  end

  def delete_tunnel(tunnel_name)
    @datapath.deleted_tunnels << tunnel_name
  end
end

class MockDpInfo < Vnet::Core::DpInfo

  attr_reader :sent_messages
  attr_accessor :current_flows
  attr_accessor :added_flows
  attr_accessor :deleted_flows
  attr_reader :added_ovs_flows
  attr_reader :added_cookie
  attr_reader :added_tunnels
  attr_reader :deleted_tunnels

  def initialize(params)
    @sent_messages = []
    @current_flows = []
    @added_flows = []
    @deleted_flows = []
    @added_ovs_flows = []
    @added_cookie = []
    @added_tunnels = []
    @deleted_tunnels = []

    @lock = Mutex.new

    super
  end

  def create_mock_port_manager
    @port_manager = MockPortManager.new(self)
  end

  def send_message(message)
    @lock.synchronize { @sent_messages << message }
  end

  def add_flow(flow)
    @lock.synchronize {
      @current_flows << flow
      @current_flows.uniq!
      @added_flows << flow
      @added_flows.uniq!
    }
  end

  def add_flows(flows)
    @lock.synchronize {
      @current_flows += flows
      @current_flows.uniq!
      @added_flows += flows
      @added_flows.uniq!
    }
  end

  def del_cookie(cookie, cookie_mask = 0xffffffffffffffff)
    @lock.synchronize {
      @added_flows.select { |f|
        (f.to_trema_hash[:cookie] & cookie_mask) == (cookie & cookie_mask)
      }.tap { |deleted_flows|
        @current_flows -= deleted_flows
        @deleted_flows += deleted_flows
        @deleted_flows.uniq!
      }
    }
  end

  def del_flows(flows)
    @lock.synchronize {
      @deleted_flows << flows
      @deleted_flows.uniq!
    }
  end

  def add_ovs_flow(ovs_flow)
    @lock.synchronize { @added_ovs_flows << ovs_flow }
  end

  def add_tunnel(tunnel_name, params = {})
    @lock.synchronize { @added_tunnels << params.merge(tunnel_name: tunnel_name) }
  end

  def delete_tunnel(tunnel_name)
    @lock.synchronize { @deleted_tunnels << tunnel_name }
  end

end

class MockDatapath < Vnet::Openflow::Datapath

  def initialize(ofc, dp_id, ofctl = nil)
    @dpid = dp_id
    @dpid_s = "0x%016x" % @dpid

    @ovs_ofctl = MockOvsOfctl.new(self)
    @controller = ofc

    @dp_info = MockDpInfo.new(controller: @controller,
                              datapath: self,
                              dpid: @dpid,
                              ovs_ofctl: @ovs_ofctl)

  end

  def create_datapath_map
    datapath_map = MW::Datapath[:dpid => @dp_info.dpid_s]
    initialize_datapath_info(datapath_map)
  end

  def create_mock_datapath_map
    datapath_map = OpenStruct.new(dpid: @dp_info.dpid_s, id: 1, uuid: 'dp-test1')
    initialize_datapath_info(datapath_map)
  end

  def create_mock_switch
    create_mock_datapath_map
    @switch = MockSwitch.new(self)
  end

  def create_mock_port_manager
    create_mock_datapath_map
    @dp_info.create_mock_port_manager
    @port_manager = @dp_info.port_manager
  end

  def mod_port(port_no, action)
  end

  private

  def do_cleanup
    info log_format('mock cleaning up')
  end  

end

def create_mock_datapath
  MockDatapath.new(double, 1).tap do |datapath|
    datapath.create_mock_datapath_map
  end
end
