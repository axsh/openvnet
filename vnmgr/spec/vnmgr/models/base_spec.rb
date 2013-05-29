require 'spec_helper'

class TestModel < Vnmgr::Models::Base; end

describe Vnmgr::Models::Base do

  let!(:test_model) do
    test_model = double("test_model")
    test_model.stub(:uuid).and_return("test-uuid")
    test_model
  end

  before(:each) do
    TestModel.stub(:[]).with("test-uuid").and_return(test_model)
  end

  describe "class methods" do
    describe "destroy" do
      it "destroy model successfully" do
        # TODO replace 'should' style to 'expect' style
        # https://github.com/rspec/rspec-mocks/issues/153
        test_model.should_receive(:destroy)
        ret = TestModel.destroy("test-uuid")
        expect(ret.uuid).to eq "test-uuid"
      end
    end

    describe "update" do
      it "update model successfully" do
        test_model.should_receive(:update).with({:name => "test"})
        ret = TestModel.update("test-uuid", {:name => "test"})
        expect(ret.uuid).to eq "test-uuid"
      end
    end
  end
end
