# -*- coding: utf-8 -*-
require 'spec_helper'

include Vnet::Constants::Openflow
include Vnet::Openflow::FlowHelpers

describe Vnet::Core::Filter2Manager do

  use_mock_event_handler

  let(:datapath) { create_mock_datapath }
  let(:flows) { datapath.dp_info.current_flows }
  let(:deleted_flows) { datapath.dp_info.deleted_flows }

  let(:filter2_manager) { datapath.dp_info.filter2_manager }
  let(:interface_manager) { datapath.dp_info.interface_manager }

  let(:filter) { Fabricate(:filter,
                           uuid: "fil-test",
                           interface_id: 1,
                           mode: "static") }

  # TODO: Sleep timers here create random fails based on load. Use wait_for_loaded.
  before(:each) do
    filter2_manager.publish(Vnet::Event::ACTIVATE_INTERFACE, id: :interface, interface_id: 1)
    sleep(0.01)
    filter2_manager.publish(Vnet::Event::FILTER_CREATED_ITEM, filter.to_hash)
    expect(filter2_manager.wait_for_loaded({id: filter.id}, 3)).not_to be_nil
  end

  shared_examples_for "filter_methods" do |operation, passthrough, event = nil|
    let(:filter) { Fabricate(:filter,
                             uuid: "fil-test",
                             interface_id: 1,
                             mode: "static",
                             egress_passthrough: passthrough[:egress],
                             ingress_passthrough: passthrough[:ingress]) }

    it "#{operation} the filter item" do

      event.call(filter2_manager, filter) unless event.nil?

      filter_hash(filter).each { |ingress, egress|
        expect(flows).to include flow(ingress)
        expect(flows).to include flow(egress)
      }
    end
  end

  shared_examples_for "added_static" do |static, protocol|

    let(:filter_static) { Fabricate(static, protocol: protocol) }

    it "adds the static" do
      static_hash(filter_static).each { |ingress, egress|
        expect(flows).to include flow(ingress)
        expect(flows).to include flow(egress)
      }
    end

  end

  describe "#created_item" do
    context "with with passthrough set to false" do
      include_examples 'filter_methods', :creates, { egress: false, ingress: false }
    end
    context "with with passthrough set to true" do
      include_examples 'filter_methods', :creates, { egress: true, ingress: true }
    end
  end

  describe "#updated_item" do
    context "with with ingress passthrough set false, egress_passthrough set true" do
      include_examples 'filter_methods', :updates, { egress: true, ingress: true }, lambda { |fm, f|
        fm.publish(Vnet::Event::FILTER_UPDATED, id: f.id, egress_passthrough: true, ingress_passthrough: false)
      }
    end
    context "with with ingress passthrough set true, egress_passthrough set false" do
      include_examples 'filter_methods', :updates, { egress: true, ingress: true }, lambda { |fm, f|
        fm.publish(Vnet::Event::FILTER_UPDATED, id: f.id, egress_passthrough: false, ingress_passthrough: true)
      }
    end
  end

  describe "#added_static" do
    before(:each) do
      filter2_manager.publish(Vnet::Event::FILTER_ADDED_STATIC,
                              filter_static.to_hash.merge(id: filter.id,
                                                          static_id: filter_static.id))
    end
    context "when protocol is tcp and passthrough is enabled" do
      include_examples 'added_static', :static_pass, "tcp"
    end
    context "when protocol is tcp and passthrough is disabled" do
      include_examples 'added_static', :static_drop, "tcp"
    end
    context "when protocol is udp and passthrough is enabled" do
      include_examples 'added_static', :static_pass, "udp"
    end
    context "when protocol is udp and passthrough is disabled" do
      include_examples 'added_static', :static_drop, "udp"
    end
    context "when protocol is icmp and passthrough is enabled" do
      include_examples 'added_static', :static_pass_without_port, "icmp"
    end
    context "when protocol is icmp and passthrough is disabled" do
      include_examples 'added_static', :static_drop_without_port, "icmp"
    end
    context "when protocol is arp and passthrough is enabled" do
      include_examples 'added_static', :static_pass_without_port, "arp"
    end
    context "when protocol is arp and passthrough is disabled" do
      include_examples 'added_static', :static_drop_without_port, "icmp"
    end
  end

  describe "#remove static" do
    before(:each) do
      filter2_manager.publish(Vnet::Event::FILTER_ADDED_STATIC,
                              filter_static.to_hash.merge(id: filter.id,
                                                          static_id: filter_static.id))
      filter2_manager.publish(Vnet::Event::FILTER_REMOVED_STATIC,
                              filter_static.to_hash.merge(id: filter.id,
                                                          static_id: filter_static.id))
    end

    context "when a static rule has been added" do
      let(:filter_static) { Fabricate(:static_pass, protocol: "tcp") }
      it "removes a static rule" do
        static_hash(filter_static).each { |ingress, egress|
          expect(flows).not_to include deleted_flow(ingress)
          expect(flows).not_to include deleted_flow(egress)

          expect(deleted_flows).to include deleted_flow(ingress)
          expect(deleted_flows).to include deleted_flow(egress)
       }
      end
    end
  end
end
