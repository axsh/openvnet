# -*- coding: utf-8 -*-
require 'spec_helper'

module Vnmgr::DataAccess::Models
  class TestModel < Base; end
end

module Vnmgr::Models
  class TestModel < Base
    attr_accessor :name
    def self.aaa
      self.new(:name => :aaa)
    end
    def to_hash
      super.tap {|h| h[:name] = self.name}
    end
  end
end

describe Vnmgr::DataAccess::Models::Base do
  subject { Vnmgr::DataAccess::Models::TestModel.new.aaa }

  context "model method not found" do
    it { expect(subject).to be_a Hash }
    it { expect(subject[:name]).to eq :aaa }
  end

  context "model method implemented" do
    before do
      Vnmgr::DataAccess::Models::TestModel.any_instance.stub(:aaa).and_return(:bbb)
    end
    it { expect(subject).to eq :bbb }
  end
end
