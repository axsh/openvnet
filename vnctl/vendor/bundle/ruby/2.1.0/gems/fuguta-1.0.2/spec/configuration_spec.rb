require 'spec_helper'

describe Fuguta::Configuration do
  class Test1 < Fuguta::Configuration
    param :param1
    param :param2
  end
  
  it "loads conf file" do
    conf = Test1.load(File.expand_path('../test1.conf', __FILE__))
    expect(conf.param1).to eq(1)
    expect(conf.param2).to eq(2)
  end

  it "loads multiple conf files" do
    conf = Test1.load(File.expand_path('../test1.conf', __FILE__), File.expand_path('../test2.conf', __FILE__))
    expect(conf.param1).to eq(10)
    expect(conf.param2).to eq(20)
  end

  it "allows nested imports/loads" do
    conf = Test1.load(File.expand_path('../nest-test1.conf', __FILE__))
    expect(conf.param1).to eq(10)
    expect(conf.param2).to eq(20)
  end
end
