# -*- coding: utf-8 -*-

def mock_dcell_me_id(node, node_id)
  allow(DCell).to receive(:me).and_return(node)
  allow(node).to receive(:id).and_return(node_id)
end

def mock_dcell_rpc(node, actor, actor_node_id)
  allow(DCell::Global).to receive(:[]).with(:rpc_node_id).and_return(actor_node_id)
  allow(DCell::Node).to receive(:[]).with(actor_node_id).and_return(node)
  allow(node).to receive(:[]).with(:rpc).and_return(actor)
end
