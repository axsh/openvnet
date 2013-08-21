# -*- coding: utf-8 -*-
require 'spec_helper'

class TestDispatcher
  include Vnet::Event::Dispatchable
end

describe Vnet::Event::Dispatchable do
  let(:dispatcher){ TestDispatcher.new }
  let(:handler){ MockEventHandler.new }

  before do
    Vnet::Event::Dispatchable.event_handler = handler
    dispatcher.dispatch_event("iface/created", {id: 3})
  end

  describe "dispatch_event" do
    subject { handler.handled_events }
    it { expect(subject.size).to eq 1 }
    it { expect(subject[0][:event]).to eq "iface/created" }
    it { expect(subject[0][:options][:id]).to eq 3 }
  end

end
