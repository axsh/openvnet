# -*- coding: utf-8 -*-
require 'spec_helper'

class TestDispatcher
  include Vnet::NodeApi::Event::Dispatchable
end

describe Vnet::NodeApi::Event::Dispatchable do
  let(:dispatcher){ TestDispatcher.new }
  let(:handler){ MockEventHandler.new }

  before do
    Vnet::NodeApi::Event::Dispatchable.event_handler = handler
    #TestDispatcher.event_handler = handler
    dispatcher.dispatch_event("vif/created", {id: 3})
  end

  describe "dispatch_event" do
    subject { handler.handled_events }
    it { expect(subject.size).to eq 1 }
    it { expect(subject[0][:event]).to eq "vif/created" }
    it { expect(subject[0][:options][:id]).to eq 3 }
  end

end
