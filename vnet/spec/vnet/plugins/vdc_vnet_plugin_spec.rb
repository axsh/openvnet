# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Plugins::VdcVnetPlugin do
  before do
    use_mock_event_handler
  end

  subject { Vnet::Plugins::VdcVnetPlugin.new }

  def deep_copy(h)
    Marshal.load( Marshal.dump(h) )
  end

  context "when an entry of Network is created on vdc" do
    let(:model_class) { :Network }
    let(:params) do
      {
        :uuid => "nw-testuuid",
        :display_name => "test_name",
        :ipv4_network => "1.2.3.0",
        :ipv4_prefix => 24,
        :domain_name => "test_domain",
        :network_mode => 'virtual',
        :editable => true
      }
    end

    describe "create_entry" do
      it "creates a record of Network on vnet" do
        subject.create_entry(model_class, deep_copy(params))
        entry = Vnet::Models::Network[params[:uuid]]

        expect(entry).not_to eq nil
        expect(entry.canonical_uuid).to eq params[:uuid]
      end
    end

    describe "destroy_entry" do
      it "deletes a record of Network on vnet" do
        subject.create_entry(model_class, deep_copy(params))
        subject.destroy_entry(model_class, deep_copy(params)[:uuid])

        expect(Vnet::Models::Network[params[:uuid]]).to eq nil
      end
    end
  end

  context "when network_vif is created" do
    let(:model_class) { :NetworkVif }
    let(:params) do
      {
        :uuid => "if-testuuid",
        :port_name => "if-testuuid",
        :mac_address => "52:54:00:12:5c:69",
      }
    end

    describe "create_entry" do
      it "creates an entry of Interface" do
        subject.create_entry(model_class, deep_copy(params))
        interface_uuid = params[:uuid].gsub("vif-", "if-")
        entry = Vnet::Models::Interface[interface_uuid]

        expect(entry).not_to eq nil
        expect(entry.canonical_uuid).to eq interface_uuid
      end
    end

    describe "destroy_entry" do
      it "deletes an entry of Interface" do
        subject.create_entry(model_class, deep_copy(params))
        subject.destroy_entry(model_class, deep_copy(params)[:uuid])
        expect(Vnet::Models::Interface[params[:uuid]]).to eq nil
      end
    end
  end
end
