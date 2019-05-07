# -*- coding: utf-8 -*-

def mock_dcell_me_id(node, node_id)
  allow(DCell).to receive(:me).and_return(node)
  allow(node).to receive(:id).and_return(node_id)
end

def mock_dcell_rpc(me_node, rpc_node, rpc_actor)
  allow(DCell).to receive(:me).and_return(me_node)
  allow(me_node).to receive(:id).and_return("me")

  allow(DCell::Node).to receive(:[]).with("vnmgr").and_return(rpc_node)
  allow(rpc_node).to receive(:[]).with(:rpc).and_return(rpc_actor)
end
