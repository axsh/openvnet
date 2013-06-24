# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

describe Vnmgr::VNet::Openflow::Switch do
  
  describe "handle_port_desc" do
    context "GRE" do
      it "should create a port objcect whose datapath_id is 1" do
        ofc = double(:ofc)
        dp = Vnmgr::VNet::Openflow::Datapath.new(ofc, 1)
        switch = Vnmgr::VNet::Openflow::Switch.new(dp)
        port_desc = double(:port_desc)
        port_desc.should_receive(:port_no).and_return(5)
        
        switch.update_bridge_hw('aaaa')
        port = double(:port)
        port_info = double(:port_info)
        port.should_receive(:port_number).and_return(5)
        port.should_receive(:port_info).exactly(3).times.and_return(port_info)
        port.should_receive(:extend).and_return(Vnmgr::VNet::Openflow::PortGre)
        port.should_receive(:install)
        port_info.should_receive(:name).exactly(3).times.and_return("t-src1dst3")
        
        Vnmgr::VNet::Openflow::Port.stub(:new).and_return(port)

        switch.handle_port_desc(port_desc)

        expect(switch.ports[5]).to eq port
      end
    end

    #TODO
    context "eth" do
    end
  end
end
