# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet/endpoints/1.0/vnet_api'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe '/filters' do
  before(:each) { use_mock_event_handler }

  let(:api_suffix)  { 'filters' }
  let(:fabricator)  { :filter }
  let(:model_class) { Vnet::Models::Filter }

  include_examples 'GET /'
  include_examples 'GET /:uuid'
  include_examples 'DELETE /:uuid'

  describe 'POST /' do
    let!(:interface) { Fabricate(:interface) { uuid 'if-filtest' } }

    expected_response = {
      :uuid => 'fil-test',
      :interface_uuid => 'if-filtest',
      :egress_passthrough => true,
      :ingress_passthrough => true,
      :mode => 'static'
    }
    accepted_params = expected_response
    required_params = [:interface_uuid, :mode]
    uuid_params = [:interface_uuid]

    include_examples 'POST /', accepted_params, required_params, uuid_params, expected_response

    context 'With a wrong value for mode' do
      let(:request_params) { accepted_params.merge({ mode: 'a squirrel' }) }

      it_should_return_error(400, 'ArgumentError')
    end
  end

  describe 'PUT /:uuid' do
    let!(:interface) { Fabricate(:interface) { uuid 'if-test' } }

    accepted_params = {
      :egress_passthrough => true,
      :ingress_passthrough => true,
    }

    include_examples 'PUT /:uuid', accepted_params
  end

  describe '/:uuid/static' do
    let!(:filter) { Fabricate(:filter, mode: 'static') }

    let(:api_suffix) { "filters/#{filter.canonical_uuid}/static" }
    let(:fabricator) { :filter_static }
    let(:model_class) { Vnet::Models::FilterStatic }

    describe 'GET' do
      before(:each) do
        entries.times { |i|
          Fabricate(fabricator, filter_id: filter.id,
                                protocol: 'tcp',
                                src_prefix: 0,
                                dst_prefix: 0,
                                src_address: 0 + i,
                                dst_address: 0,
                                port_src: 0,
                                port_dst: 0)
        }

        get api_suffix
      end

      context 'with no entries in the database' do
        let(:entries) { 0 }

        it 'should return json with empty items' do
          expect(last_response).to succeed.with_body({
            'total_count' => 0,
            'offset' =>  0,
            'limit' => Vnet::Configurations::Webapi.conf.pagination_limit,
            'items' => [],
          })
        end
      end

      test_with_db_entries 3

      context 'with a different filter id' do
        let(:entries) { 3 }
        let(:api_suffix) {
          new_filter = Fabricate(:filter, mode: 'static')
          "filters/#{new_filter.canonical_uuid}/static"
        }

        it 'does not return entries from the initial id' do
          expect(last_response).to succeed.with_body({
            'total_count' => 0,
            'offset' =>  0,
            'limit' => Vnet::Configurations::Webapi.conf.pagination_limit,
            'items' => [],
          })
        end
      end
    end

    shared_examples_for 'DELETE mode' do |accepted_params, required_params, uuid_params|
      let!(:filter_to_delete) { Fabricate(:filter_static, db_fields) }

      before(:each) { delete api_suffix, request_params }

      include_examples "fails without the required parameters", accepted_params, required_params

      # context 'with parameters describing a non existing static filter' do
      #   # let(:request_params) { accepted_params.merge(action: 'drop') }
      #   let(:request_params) { accepted_params }

      #   it_should_return_error(404, 'UnknownResource')
      # end

      context 'with parameters describing an existing static filter' do
        let(:request_params) { accepted_params }

        it 'should delete one database entry' do
          expect(last_response).to succeed
          expect(model_class.find(db_fields)).to eq(nil)
        end
      end
    end

    ['tcp', 'udp'].each { |protocol|
      describe protocol do
        accepted_params = {
          protocol: protocol,          
          dst_address: '192.168.100.150',
          dst_port: 24056
        }
        required_params = [:protocol]
        uuid_params = []

        describe 'POST' do
          include_examples 'POST /', accepted_params.merge(action: 'pass'), required_params.dup.push(:action), uuid_params
        end

        describe 'DELETE' do
          let(:db_fields) {
            { filter_id: filter.id,
              protocol: protocol,
              dst_address: 3232261270,
              dst_prefix: 32,
              src_address: 0,
              src_prefix: 0,
              port_dst: 24056,
              port_src: 0,
              action: 'pass'
            }
          }

          # TODO: Figure out how to deal with required_params when
          # missing parameters now become wildcards.
          include_examples 'DELETE mode', accepted_params, [], uuid_params
        end
      end
    }

    describe 'icmp' do
      accepted_params = {
        protocol: 'icmp',
        dst_address: '192.168.100.150',
      }
      required_params = [:protocol]
      uuid_params = []

      describe 'POST' do
        include_examples 'POST /', accepted_params.merge(action: 'pass'), required_params.dup.push(:action), uuid_params
      end

      describe 'DELETE' do
        let(:db_fields) {
          { filter_id: filter.id,
            dst_address: 3232261270,
            dst_prefix: 32,
            src_address: 0,
            src_prefix: 0,
            port_src: nil,
            port_dst: nil,
            protocol: 'icmp',
            action: 'pass'
          }
        }

        include_examples 'DELETE mode', accepted_params, required_params, uuid_params
      end
    end

    describe 'arp' do
      accepted_params = {
        protocol: 'arp',
        action: 'pass'
      }
      required_params = [:protocol]
      uuid_params = []

      describe 'POST' do
        include_examples 'POST /', accepted_params.merge(action: 'pass'), required_params.dup.push(:action), uuid_params
      end

      describe 'DELETE' do
        let(:db_fields) {
          { filter_id: filter.id,
            src_address: 0,
            src_prefix: 0,
            dst_address: 0,
            dst_prefix: 0,
            port_src: nil,
            port_dst: nil,
            protocol: 'arp',
            action: 'pass'
          }
        }

        include_examples 'DELETE mode', accepted_params, required_params, uuid_params
      end
    end
  end
end
