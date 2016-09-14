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
    @datapath_info = Vnet::Openflow::DatapathInfo.new(MW::Datapath[:dpid => @dp_info.dpid_s])
    initialize_managers
  end

  def create_mock_datapath_map
    @datapath_info = Vnet::Openflow::DatapathInfo.new(OpenStruct.new(dpid: @dp_info.dpid_s, id: 1, uuid: 'dp-test1'))
    initialize_managers
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
