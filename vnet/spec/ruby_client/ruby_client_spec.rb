# -*- coding: utf-8 -*-
require 'spec_helper'

def app
  Vnet::Endpoints::V10::VnetAPI
end

include Rack::Test::Methods
api_specs = YAML.load(get("browse", format: :yaml).body)

expected_classes = {}

api_specs.each { |api_spec|
  verb, suffix = api_spec[:route].split('  ')
  underscored = suffix.split('/')[1]
  next if underscored == 'browse'

  class_name = underscored.chomp('s').split('_').collect!{ |w| w.capitalize }.join

  expected_classes[class_name] ||= []

  case api_spec[:route]
  when "POST  /#{underscored}"
    expected_classes[class_name] << :create
  when "GET  /#{underscored}"
    expected_classes[class_name] << :index
  when "GET  /#{underscored}/:uuid"
    expected_classes[class_name] << :show
  when "PUT  /#{underscored}/:uuid"
    expected_classes[class_name] << :update
  when "DELETE  /#{underscored}/:uuid"
    expected_classes[class_name] << :delete
  when /^POST  \/#{underscored}\/:[a-z\_]+\/[a-z\_]+\/:[a-z\_]+$/
    # This matches for example: POST  /datapaths/:uuid/networks/:network_uuid
    relation_name = api_spec[:route].split('/')[3].chomp('s')
    expected_classes[class_name] << "add_#{relation_name}"
  end
}

describe VNetAPIClient do
  expected_classes.each do |class_name, methods|
    describe class_name do

      let(:klass) { VNetAPIClient.const_get(class_name) }

      it "exists" do
        klass
      end

      methods.each do |method|
        it "has the '#{method}' method" do
          expect(klass).to respond_to(method)
        end
      end

    end
  end
end

