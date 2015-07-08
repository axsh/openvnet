# -*- coding: utf-8 -*-
require 'spec_helper'

def app
  Vnet::Endpoints::V10::VnetAPI
end

# Use Rack::Test to made all call to the VNet API and get the generated documentation
# from Sinatra-browse in YAML format. We choose YAML over JSON because the VNet API
# has some Ruby ranges that would expand into huge arrays in JSON.
include Rack::Test::Methods
api_specs = YAML.load(get("browse", format: :yaml).body)


# Now that we have the API descriptions in a ruby hash, we are going to parse them
# into a format that will make it easier to write tests.
expected_classes = {}
non_standard_routes = []
named_args_regex = /:[a-z\_]+/

api_specs.each { |api_spec|
  verb, suffix = api_spec[:route].split('  ')
  underscored = suffix.split('/')[1]

  # The 'browse' route is added by Sinatra-browse and doesn't need to be included
  # in the VNet API client
  next if underscored == 'browse'

  class_name = underscored.classify

  expected_classes[class_name] ||= {}

  case route = api_spec[:route]
  when "POST  /#{underscored}"
    expected_classes[class_name][:create] = route
  #TODO: Use regex here
  when "GET  /#{underscored}"
    expected_classes[class_name][:index] = route
  when "GET  /#{underscored}/:uuid"
    expected_classes[class_name][:show] = route
  when "PUT  /#{underscored}/:uuid"
    expected_classes[class_name][:update] = route
  when "DELETE  /#{underscored}/:uuid"
    expected_classes[class_name][:delete] = route
  when /^POST  \/#{underscored}\/#{named_args_regex}+\/[a-z\_]+\/#{named_args_regex}+$/
    # This matches for example: POST  /datapaths/:uuid/networks/:network_uuid
    relation_name = route.split('/')[3].chomp('s')
    expected_classes[class_name]["add_#{relation_name}"] = route
  when /^GET  \/#{underscored}\/#{named_args_regex}+\/[a-z\_]+$/
    # This matches for example: GET  /datapaths/:uuid/networks
    relation_name = route.split('/')[3]
    expected_classes[class_name]["show_#{relation_name}"] = route
  when /^DELETE  \/#{underscored}\/#{named_args_regex}+\/[a-z\_]+\/#{named_args_regex}+$/
    # This matches for example: DELETE  /datapaths/:uuid/networks/:network_uuid
    relation_name = route.split('/')[3].chomp('s')
    expected_classes[class_name]["remove_#{relation_name}"] = route
  else
    non_standard_routes << route
  end
}

shared_examples_for "test_method" do |method, route|
  verb, uri = route.split('  ')

  non_standard_routes.delete(route)

  describe "##{method}" do
    it "makes a #{verb} request to '#{uri}'" do
      arguments = uri.scan(/:[a-z\_]+/n).map { |arg| "test_id" }
      uri_with_args = uri.gsub(/:[a-z\_]+/, 'test_id')

      stubby = stub_request(verb.downcase.to_sym,
                            "http://localhost:9101/api/1.0#{uri_with_args}.json")
      klass.send(method, *arguments)

      assert_requested(stubby)
    end
  end
end

describe VNetAPIClient do
  let(:klass) { described_class }

  # First we test all standard methods
  expected_classes.each do |class_name, methods|
    describe VNetAPIClient.const_get(class_name) do

      let(:klass) { VNetAPIClient.const_get(class_name) }

      it "exists" do
        klass
      end

      methods.each { |method, route| include_examples 'test_method', method, route }

    end
  end

  # Next we test all non standard methods
  describe VNetAPIClient::DnsService do
    include_examples 'test_method', :add_dns_record,
                     "POST  /dns_services/:dns_service_uuid/dns_records"
  end

  describe VNetAPIClient::Interface do
    include_examples 'test_method', :rename, 'PUT  /interfaces/:uuid/rename'
    include_examples 'test_method', :add_port, 'POST  /interfaces/:uuid/ports'
    include_examples 'test_method', :remove_port, 'DELETE  /interfaces/:uuid/ports'
  end

  describe VNetAPIClient::IpRangeGroup do
    include_examples 'test_method', :add_range,
                     'POST  /ip_range_groups/:ip_range_group_uuid/ip_ranges'
  end

  describe VNetAPIClient::LeasePolicy do
    include_examples 'test_method', :add_lease,
                     'POST  /lease_policies/:uuid/ip_leases'
  end

  describe VNetAPIClient::Translation do
    include_examples 'test_method', :add_static_address,
                     'POST  /translations/:uuid/static_address'
    include_examples 'test_method', :remove_translation,
                     'DELETE  /translations/:uuid/static_address'
  end

  # Finally we make sure that no standard methods are left unimplemented/untested
  it "has implemented and tested all routes in the OpenVNet WebAPI" do
    if ! non_standard_routes.empty?
      raise "The following routes where not tested and might not be implemented:\n%s" %
        non_standard_routes.join("\n")
    end
  end
end

