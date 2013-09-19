# -*- coding: utf-8 -*-
class MockDatapath < Vnet::Openflow::Datapath
  attr_reader :sent_messages
  attr_reader :added_flows
  attr_reader :added_ovs_flows
  attr_reader :added_tunnels
  attr_reader :added_cookie
  attr_reader :deleted_tunnels

  def initialize(*args)
    super(*args)
    @sent_messages = []
    @added_flows = []
    @added_ovs_flows = []
    @added_tunnels = []
    @added_cookie = []
    @deleted_tunnels = []
  end

  def create_datapath_map
    @datapath_map = MW::Datapath[:dpid => ("0x%016x" % @dpid)]
  end

  def create_mock_datapath_map
    @datapath_map = OpenStruct.new(dpid: ("0x%016x" % @dpid),
                                   id: 1)
  end

  def create_mock_switch
    create_mock_datapath_map
    @switch = MockSwitch.new(self)
  end

  def create_mock_port_manager
    create_mock_datapath_map
    @port_manager = MockPortManager.new(self)
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

  def add_tunnel(tunnel_name, remote_ip)
    @added_tunnels << {:tunnel_name => tunnel_name, :remote_ip => remote_ip}
  end

  def delete_tunnel(tunnel_name)
    @deleted_tunnels << tunnel_name
  end
end
