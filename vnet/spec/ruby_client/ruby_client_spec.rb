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

  expected_classes[class_name] ||= {non_standard: []}

  case route = api_spec[:route]
  when "POST  /#{underscored}"
    expected_classes[class_name][:create] = route
  when "GET  /#{underscored}"
    expected_classes[class_name][:index] = route
  when "GET  /#{underscored}/:uuid"
    expected_classes[class_name][:show] = route
  when "PUT  /#{underscored}/:uuid"
    expected_classes[class_name][:update] = route
  when "DELETE  /#{underscored}/:uuid"
    expected_classes[class_name][:delete] = route
  when /^POST  \/#{underscored}\/:[a-z\_]+\/[a-z\_]+\/:[a-z\_]+$/
    # This matches for example: POST  /datapaths/:uuid/networks/:network_uuid
    relation_name = route.split('/')[3].chomp('s')
    expected_classes[class_name]["add_#{relation_name}"] = route
  when /^GET  \/#{underscored}\/:[a-z\_]+\/[a-z\_]+$/
    # This matches for example: GET  /datapaths/:uuid/networks
    relation_name = route.split('/')[3]
    expected_classes[class_name]["show_#{relation_name}"] = route
  when /^DELETE  \/#{underscored}\/:[a-z\_]+\/[a-z\_]+\/:[a-z\_]+$/
    # This matches for example: DELETE  /datapaths/:uuid/networks/:network_uuid
    relation_name = route.split('/')[3].chomp('s')
    expected_classes[class_name]["remove_#{relation_name}"] = route
  else
    expected_classes[class_name][:non_standard] << route
  end
}

describe VNetAPIClient do
  expected_classes.each do |class_name, methods|
    describe class_name do

      let(:klass) { VNetAPIClient.const_get(class_name) }

      it "exists" do
        klass
      end

      non_standard_routes = methods.delete(:non_standard)
      it "has implemented and tested all corresponding API routes" do
        if ! non_standard_routes.empty?
          raise "The following routes where not tested and might not be implemented:\n%s" %
            non_standard_routes.join("\n")
        end
      end

      methods.each do |method, route|
        verb, uri = route.split('  ')

        describe "##{method}" do
          it "makes a #{verb} request to '#{uri}'" do
            arguments = uri.scan(/:[a-z_]+/).map { |arg| "test_id" }
            uri_with_args = uri.gsub(/:[a-z_]+/, 'test_id')

            stubby = stub_request(verb.downcase.to_sym,
                                  "http://localhost:9101/api/1.0#{uri_with_args}.json")
            klass.send(method, *arguments)

            assert_requested(stubby)
          end
        end
      end

    end
  end
end

