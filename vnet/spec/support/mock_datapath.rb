# -*- coding: utf-8 -*-

class MockOvsOfctl
  def initialize(datapath)
    @datapath = datapath
  end

  def mod_port(port_no, action)
  end

  def add_tunnel(tunnel_name, remote_ip)
    @datapath.added_tunnels << {:tunnel_name => tunnel_name, :remote_ip => remote_ip}
  end

  def delete_tunnel(tunnel_name)
    @datapath.deleted_tunnels << tunnel_name
  end
end

class MockDpInfo < Vnet::Openflow::DpInfo

  attr_reader :added_tunnels
  attr_reader :deleted_tunnels

  def initialize(params)
    super

    @added_tunnels = []
    @deleted_tunnels = []
  end

  def create_mock_port_manager
    @port_manager = MockPortManager.new(self)
  end

  def send_message(message)
    @datapath.sent_messages << message
  end

  def add_flow(flow)
    @datapath.add_flow(flow)
  end

  def add_flows(flows)
    @datapath.add_flows(flows)
  end

  def del_cookie(cookie)
    @datapath.added_flows.delete_if {|f| f.to_trema_hash[:cookie] == cookie }
  end

  def add_ovs_flow(ovs_flow)
    @datapath.added_ovs_flows << ovs_flow
  end

  def add_tunnel(tunnel_name, remote_ip)
    @added_tunnels << {:tunnel_name => tunnel_name, :remote_ip => remote_ip}
  end

  def delete_tunnel(tunnel_name)
    @deleted_tunnels << tunnel_name
  end
end

class MockDatapath < Vnet::Openflow::Datapath
  attr_reader :sent_messages
  attr_accessor :added_flows
  attr_reader :added_ovs_flows
  attr_reader :added_cookie

  def initialize(ofc, dp_id, ofctl = nil)
    @dpid = dp_id
    @dpid_s = "0x%016x" % @dpid

    @ovs_ofctl = MockOvsOfctl.new(self)
    @controller = ofc

    @sent_messages = []
    @added_flows = []
    @added_ovs_flows = []
    @added_cookie = []

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
    datapath_map = OpenStruct.new(dpid: @dp_info.dpid_s, id: 1)
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

  def send_message(message)
    @sent_messages << message
  end

  def add_flow(flow)
    @added_flows << flow
  end

  def add_flows(flows)
    @added_flows += flows
  end

  def del_cookie(cookie)
    @added_flows.delete_if {|f| f.to_trema_hash[:cookie] == cookie }
  end

  def add_ovs_flow(ovs_flow)
    @added_ovs_flows << ovs_flow
  end

  def mod_port(port_no, action)
  end

end
