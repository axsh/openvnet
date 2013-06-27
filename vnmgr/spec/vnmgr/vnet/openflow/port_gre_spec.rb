# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

include Vnmgr::VNet::Openflow::Constants

describe Vnmgr::VNet::Openflow::PortGre do
  describe "install" do
    it "should create a port objcect whose datapath_id is 1" do
      port_number = 10
      dp = double(:datapath)
      port_info = double(:port_info)
      port_info.should_receive(:port_no).and_return(port_number)
      port = Vnmgr::VNet::Openflow::Port.new(dp, port_info, true)
      port.extend(Vnmgr::VNet::Openflow::PortGre)
      switch = double(:switch)
      dp.should_receive(:switch).and_return(switch)
      nm = double(:nm)
      switch.should_receive(:network_manager).and_return(nm)
      nm.should_receive(:update_all_flows)
      port.install
    end
  end
end
