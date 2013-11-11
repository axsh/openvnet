# -*- coding: utf-8 -*-

shared_context :ofc_double do
  let(:ofc) { double(:ofc).tap {|c| c.should_receive(:pass_task).twice} }
end