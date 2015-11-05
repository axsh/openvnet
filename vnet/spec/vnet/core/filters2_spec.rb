require 'spec_helper'

include Vnet::Constants::Openflow
include Vnet::Openflow::FlowHelpers

describe Vnet::Core::Filter2Manager do

  let(:datapath) { MockDatapath.new(double, ("a" * 16).to_i) }
  let(:dp_info) { datapath.dp_info }
  let(:flows) { dp_info.current_flows }
  let(:deleted_flows) { dp_info.deleted_flows }

  let(:interface) { Fabricate(:filter_interface,
                              uuid: "if-filter",
                              ingress_filtering_enabled: false,
                              enable_filtering: true
                             ) }

  let(:filter) { Fabricate(:filter,
                           uuid: "fil-test",
                           interface_id: "if-filter",
                           mode: "static"
                          ) }

  let(:filter_static) { Fabricate(:filter_static,
                                  protocol: "tcp",
                                  ipv4_address: "10.101.0.11",
                                  port_number: 80
                                 ) }

  subject {  Vnet::Core::Filter2Manager.new(datapath) }

  describe "#created_item" do
    before(:each) do
      subject.publish(Vnet::Event::FILTER_CREATED_ITEM, filter.to_hash)
    end

    it "creates the a filter item" do
    end
  end

  describe "#added_static" do
    before(:each) do
      model_hash = filter_static.to_hash.merge(id: filter.id, static_id: filter_static.id)
      subject.publish(Vnet::Event::FILTER_ADDED_STATIC, model_hash)
    end

    it "adds and installs a static rule" do
    end
  end

  describe "#remove static" do
    before(:each) do
      subject.publish(Vnet::Event::FILTER_REMOVED_STATIC, id: filter.id, static_id: filter_static.id)
    end

    it "removes a static rule" do
    end
  end
end
