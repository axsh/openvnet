# -*- coding: utf-8 -*-

require 'spec_helper'
require_relative 'filters/helpers2'

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
                           mode: "static",
                          )
  }

    before(:each) do
    filter2_manager.publish(Vnet::Event::FILTER_ACTIVATE_INTERFACE, id: :interface, interface_id: 1)
    sleep(1)
    filter2_manager.publish(Vnet::Event::FILTER_CREATED_ITEM, filter.to_hash)
    sleep(1)
  end

  describe "#created_item" do
    context "with with passthrough set to false" do
      let(:filter) { Fabricate(:filter,
                               uuid: "fil-test",
                               interface_id: 1,
                               mode: "static",
                               egress_passthrough: false,
                               ingress_passthrough: false
                              )
      }
      it "creates the a filter item" do
        filter_hash(filter).each { |ingress, egress|
          expect(flows).to include flow(ingress)
          expect(flows).to include flow(egress)
        }
      end
    end
    context "with with passthrough set to true" do
      let(:filter) { Fabricate(:filter,
                               uuid: "fil-test",
                               interface_id: 1,
                               mode: "static",
                               egress_passthrough: true,
                               ingress_passthrough: true
                              )
      }
      it "creates the a filter item" do
        filter_hash(filter).each { |ingress, egress|
          expect(flows).to include flow(ingress)
          expect(flows).to include flow(egress)
        }
      end
    end
  end

  describe "#updated_item" do
    context "with with ingress passthrough set false, egress_passthrough set true" do
      let(:filter) { Fabricate(:filter,
                               uuid: "fil-test",
                               interface_id: 1,
                               mode: "static",
                               egress_passthrough: true,
                               ingress_passthrough: false
                              )
      }
      it "updates the a filter item" do
        filter2_manager.publish(Vnet::Event::FILTER_UPDATED, id: filter.id, ingress_passthrough: false, egress_passthrough: true)
        sleep(1)

        filter_hash(filter).each { |ingress, egress|
          expect(flows).to include flow(ingress)
          expect(flows).to include flow(egress)
        }
      end
    end
    context "with with ingress passthrough set true, egress_passthrough set false" do
      let(:filter) { Fabricate(:filter,
                               uuid: "fil-test",
                               interface_id: 1,
                               mode: "static",
                               egress_passthrough: false,
                               ingress_passthrough: true
                              )
      }
      it "updates the a filter item" do
        filter2_manager.publish(Vnet::Event::FILTER_UPDATED, id: filter.id, ingress_passthrough: true, egress_passthrough: false)
        sleep(1)

        filter_hash(filter).each { |ingress, egress|
          expect(flows).to include flow(ingress)
          expect(flows).to include flow(egress)
        }        
      end
    end
  end

  describe "#added_static" do
    before(:each) do
      filter2_manager.publish(Vnet::Event::FILTER_ADDED_STATIC,
                              filter_static.to_hash.merge(id: filter.id,
                                                          static_id: filter_static.id))
      sleep(1)
    end
    context "when protocol is tcp and passthrough is enabled" do
      let(:filter_static) { Fabricate(:static_tcp_pass) }
      it "adds the static" do
        static_hash(filter_static).each { |ingress, egress|
          expect(flows).to include flow(ingress)
          expect(flows).to include flow(egress)
        }
      end
    end
    context "when protocol is tcp and passthrough is disabled" do
      let(:filter_static) { Fabricate(:static_tcp_drop) }
      it "adds he static" do
        static_hash(filter_static).each { |ingress, egress|
          expect(flows).to include flow(ingress)
          expect(flows).to include flow(egress)
        }
      end
    end
    context "when protocol is udp and passthrough is enabled" do
      let(:filter_static) { Fabricate(:static_udp_pass) }
      it "adds he static" do
        static_hash(filter_static).each { |ingress, egress|
          expect(flows).to include flow(ingress)
          expect(flows).to include flow(egress)
        }
      end
    end
    context "when protocol is udp and passthrough is disabled" do
      let(:filter_static) { Fabricate(:static_udp_drop) }
      it "adds he static" do
        static_hash(filter_static).each { |ingress, egress|
          expect(flows).to include flow(ingress)
          expect(flows).to include flow(egress)
        }
      end
    end
    context "when protocol is icmp and passthrough is enabled" do
      let(:filter_static) { Fabricate(:static_icmp_pass) }
      it "adds he static" do
        static_hash(filter_static).each { |ingress, egress|
          expect(flows).to include flow(ingress)
          expect(flows).to include flow(egress)
        }
      end
    end
    context "when protocol is icmp and passthrough is disabled" do
      let(:filter_static) { Fabricate(:static_icmp_drop) }
      it "adds he static" do
        static_hash(filter_static).each { |ingress, egress|
          expect(flows).to include flow(ingress)
          expect(flows).to include flow(egress)
        }
      end
    end
    context "when protocol is arp and passthrough is enabled" do
      let(:filter_static) { Fabricate(:static_arp_pass) }
      it "adds he static" do
        static_hash_arp(filter_static).each { |ingress, egress|
          expect(flows).to include flow(ingress)
          expect(flows).to include flow(egress)
        }
      end
    end
    context "when protocol is arp and passthrough is disabled" do
      let(:filter_static) { Fabricate(:static_arp_drop) }
      it "adds he static" do
        static_hash_arp(filter_static).each { |ingress, egress|
          expect(flows).to include flow(ingress)
          expect(flows).to include flow(egress)
        }
      end
    end
  end

  describe "#remove static" do
    before(:each) do
    end

    it "removes a static rule" do
    end
  end
end
