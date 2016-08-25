# -*- coding: utf-8 -*-

shared_examples 'GET many_to_many_relation' do |relation_suffix, get_request_params|
  describe "GET /:uuid/#{relation_suffix}" do
    let(:api_relation_suffix) { "#{api_suffix}/#{base_object.canonical_uuid}/#{relation_suffix}" }

    before(:each) do
      add_relation = "add_#{relation_suffix.chomp('s')}"

      entries.times {
        base_object.send(add_relation, Fabricate(relation_fabricator))
      }

      get api_relation_suffix
    end

    context 'With no relations in the database' do
      let(:entries) { 0 }

      it 'should return a json with empty relations' do
        expect(last_response).to succeed.with_body({
          'total_count' => 0,
          'offset' =>  0,
          'limit' => Vnet::Configurations::Webapi.conf.pagination_limit,
          'items' => [],
        })

        expect(JSON.parse(last_response.body)['items'].size).to eq 0
      end
    end

    context 'With 3 relations in the database' do
      let(:entries) { 3 }

      it 'should return a json with 3 relations in it' do
        expect(last_response).to succeed.with_body_containing({
          'total_count' => 3,
          'offset' =>  0,
          'limit' => Vnet::Configurations::Webapi.conf.pagination_limit,
        })

        expect(JSON.parse(last_response.body)['items'].size).to eq 3
      end
    end
  end
end

shared_examples 'POST many_to_many_relation' do |relation_suffix, post_request_params|
  let!(:related_object) { Fabricate(relation_fabricator) }

  describe "POST /:uuid/#{relation_suffix}/:#{relation_suffix.chomp('s')}_uuid" do
    before(:each) do
      post api_relation_suffix, request_params
    end

    let(:request_params) { post_request_params }

    include_examples 'relation_uuid_checks', relation_suffix

    context 'with a related object that isn\'t added to the base object yet' do
      let(:api_relation_suffix) {
        "#{api_suffix}/#{base_object.canonical_uuid}/#{relation_suffix}/#{related_object.canonical_uuid}"
      }

      it 'should create a new entry in the join table' do
        expect(last_response).to succeed
        expect(base_object.send(relation_suffix)).to eq [related_object]
      end
    end
  end
end

shared_examples 'PUT many_to_many_relation' do |relation_suffix, accepted_params, required_params = [], uuid_params = [], expected_response = nil|
  expected_response ||= accepted_params

  before(:each) do
    # TODO: Move to helper method.
    base_name = base_object.class.name.demodulize.underscore
    relation_name = related_object.class.name.demodulize.underscore

    fabricator_name =
      if respond_to?(:join_table_fabricator)
        join_table_fabricator
      else
        "#{base_name}_#{relation_name}".to_sym
      end

    Fabricate(
      fabricator_name,
      :"#{base_name}_id" => base_object.id,
      :"#{relation_name}_id" => related_object.id
    )

    put api_relation_suffix, request_params
  end

  let!(:related_object) { Fabricate(relation_fabricator) }
  let(:request_params) { accepted_params }
  let!(:object) { Fabricate(fabricator) }

  #describe "PUT /:uuid/#{relation_suffix}/:#{relation_suffix.chomp('s')}_uuid" do

  include_examples 'relation_uuid_checks', relation_suffix

  context "with an existing uuid" do
    let(:api_relation_suffix) {
      "#{api_suffix}/#{base_object.canonical_uuid}/#{relation_suffix}/#{related_object.canonical_uuid}"
    }

    uuid_params.each { |up| include_examples "uuid_in_param", accepted_params, up }

    context "with only the required parameters" do
      let(:request_params) do
        accepted_params.dup.tap { |n|
          n.delete_if { |k,v| !required_params.member?(k) }
        }
      end

      it "should create a database entry the required parameters set" do
        expect(last_response).to succeed.with_body_containing(request_params)
      end
    end

    context "with all accepted parameters" do
      let(:request_params) { accepted_params }

      it "should create a database entry with all parameters set" do
        expect(last_response).to succeed.with_body_containing(expected_response)
      end
    end
  end
end


shared_examples 'DELETE many_to_many_relation' do |relation_suffix, delete_request_params|
  let!(:related_object) { Fabricate(relation_fabricator) }

  relation_uuid_label = ":#{relation_suffix.chomp('s')}_uuid"

  describe "DELETE /:uuid/#{relation_suffix}/#{relation_uuid_label}" do
    let(:request_params) { Hash.new }

    before(:each) do
      base_name = base_object.class.name.demodulize.underscore
      relation_name = related_object.class.name.demodulize.underscore

      fabricator_name =
        if respond_to?(:join_table_fabricator)
          join_table_fabricator
        else
          "#{base_name}_#{relation_name}".to_sym
        end

      Fabricate(
        fabricator_name,
        :"#{base_name}_id" => base_object.id,
        :"#{relation_name}_id" => related_object.id
      )

      delete api_relation_suffix, request_params
    end

    include_examples 'relation_uuid_checks', relation_suffix, relation_uuid_label

    context 'with a related object that has already been added to the base object' do
      let(:api_relation_suffix) {
        "#{api_suffix}/#{base_object.canonical_uuid}/#{relation_suffix}/#{related_object.canonical_uuid}"
      }

      it 'should destroy the entry in the join table' do
        expect(last_response).to succeed
        expect(base_object.send(relation_suffix)).to eq []
      end
    end
  end
end

shared_examples 'many_to_many_relation' do |relation_suffix, post_request_params|
  include_examples 'POST many_to_many_relation', relation_suffix, post_request_params
  include_examples 'GET many_to_many_relation', relation_suffix, {}
  include_examples 'DELETE many_to_many_relation', relation_suffix, {}
end
