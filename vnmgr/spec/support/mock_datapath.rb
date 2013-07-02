# -*- coding: utf-8 -*-
class MockDatapath < Vnmgr::VNet::Openflow::Datapath
  attr_reader :sent_messages
  attr_reader :added_flows
  attr_reader :added_ovs_flows
  def initialize(*args)
    super(*args)
    @sent_messages = []
    @added_flows = []
    @added_ovs_flows = []
  end

  def send_message(message)
    @sent_messages << message
  end

  def add_flows(flows)
    @added_flows += flows
  end

  def add_ovs_flow(ovs_flow)
    @added_ovs_flows << ovs_flow
  end
end
