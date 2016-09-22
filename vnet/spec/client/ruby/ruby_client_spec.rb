# -*- coding: utf-8 -*-
require 'spec_helper'

$LOAD_PATH.unshift File.expand_path("#{Vnet::ROOT}/../client/ruby/lib")
require 'vnet_api_client'


# We use Rack::Test to make a call to the VNet API and get the generated documentation
# from Sinatra-browse in YAML format. We choose YAML over JSON because the VNet API
# has some Ruby ranges that would expand into huge arrays in JSON.
class SinatraBrowsePoller
  class << self
    include Rack::Test::Methods

    def app
      Vnet::Endpoints::V10::VnetAPI
    end

    def poll
      YAML.load(get("browse", format: :yaml).body)
    end
  end
end
api_specs = SinatraBrowsePoller.poll


# Now that we have the API descriptions in a ruby hash, we are going to parse them
# into a format that will make it easier to write tests.
expected_classes = {}
non_standard_routes = []
named_args_regex = /:[a-z\_]+/

api_specs.each { |api_spec|
  verb, suffix = api_spec[:route].split('  ')
  underscored = suffix.split('/')[1]

  # The 'browse' route is added by Sinatra-browse and doesn't need to be included
  # in the VNet API client gem.
  next if underscored == 'browse'

  # Determine the class that should represent this WebAPI namespace in the gem.
  class_name = underscored.classify
  expected_classes[class_name] ||= {}

  case route = api_spec[:route]
  #
  # First we identify the standard CRUD routes. A lot of endpoints are going to
  # have these and we know exactly which methods should be in the VNetAPIClient gem
  # for them. We will generate tests for them automatically.
  #
  # Examples of matches:
  #
  # POST  /datapaths
  # GET  /lease_policies
  # GET  /interfaces/:uuid
  # PUT  /ip_range_groups/:uuid
  # DELETE  /ip_leases/:uuid
  #
  when "POST  /#{underscored}"
    expected_classes[class_name][:create] = route
  when "GET  /#{underscored}"
    expected_classes[class_name][:index] = route
  when /^GET  \/#{underscored}\/#{named_args_regex}+$/
    expected_classes[class_name][:show] = route
  when /^PUT  \/#{underscored}\/#{named_args_regex}+$/
    expected_classes[class_name][:update] = route
  when /^DELETE  \/#{underscored}\/#{named_args_regex}+$/
    expected_classes[class_name][:delete] = route
  #
  # Next we identify the CRD routes for relations. Again a lot of endpoints are
  # going to have these and we know exactly which methods should be present in
  # the gem. We will generate tests for these automatically too.
  #
  # Examples of matches:
  #
  #  POST  /datapaths/:uuid/networks/:network_uuid
  #  GET  /datapaths/:uuid/networks
  #  PUT  /datapaths/:uuid/networks/:network_uuid
  #  DELETE  /datapaths/:uuid/networks/:network_uuid
  #
  when /^POST  \/#{underscored}\/#{named_args_regex}+\/[a-z\_]+\/#{named_args_regex}+$/
    relation_name = route.split('/')[3].chomp('s')
    expected_classes[class_name]["add_#{relation_name}"] = route
  when /^GET  \/#{underscored}\/#{named_args_regex}+\/[a-z\_]+$/
    relation_name = route.split('/')[3]
    expected_classes[class_name]["show_#{relation_name}"] = route
  when /^PUT  \/#{underscored}\/#{named_args_regex}+\/[a-z\_]+\/#{named_args_regex}+$/
    relation_name = route.split('/')[3].chomp('s')
    expected_classes[class_name]["update_#{relation_name}"] = route
  when /^DELETE  \/#{underscored}\/#{named_args_regex}+\/[a-z\_]+\/#{named_args_regex}+$/
    relation_name = route.split('/')[3].chomp('s')
    expected_classes[class_name]["remove_#{relation_name}"] = route
  else
  #
  # Any route that doesn't match the above, we will refer to as a non standard
  # route. We do not know exactly which method the gem will define for these
  # but since they exist in the API, the gem is still required to implement them.
  #
  # Tests for these have to be written manually. The test suite will be red if
  # not all of these are accounted for.
  #
    non_standard_routes << route
  end
}

shared_examples_for "test_method" do |method, route|
  verb, uri = route.split('  ')

  non_standard_routes.delete(route)

  describe "##{method}" do
    it "makes a #{verb} request to '#{uri}'" do
      arguments = uri.scan(named_args_regex).map { |arg| "test_id" }
      uri_with_args = uri.gsub(named_args_regex, 'test_id')

      stubby = stub_request(verb.downcase.to_sym,
                            "http://localhost:9090/api/1.0#{uri_with_args}.json")
      klass.send(method, *arguments)

      assert_requested(stubby)
    end
  end
end

describe VNetAPIClient do
  # This let is here so we can use the "test_method" shared examples without
  # having to define the let(:klass) every time. This is used in the non standard
  # route tests below
  let(:klass) { described_class }

  #
  # First we test all standard methods
  #
  expected_classes.each do |class_name, methods|
    # We describe a string here instead of a constant. That's because of the
    # 'it "exists" do' test below. If we were discribing a non-existant class
    # here the test suite would crash and not test any of the classes that do
    # exist
    describe class_name do

      let(:klass) { VNetAPIClient.const_get(class_name) }

      it "exists" do
        klass
      end

      methods.each { |method, route| include_examples 'test_method', method, route }

    end
  end

  #
  # Next we test all non standard routes
  #
  describe VNetAPIClient::DnsService do
    include_examples 'test_method', :add_dns_record,
                     "POST  /dns_services/:dns_service_uuid/dns_records"
  end

  describe VNetAPIClient::Interface do
    include_examples 'test_method', :rename, 'PUT  /interfaces/:uuid/rename'
    include_examples 'test_method', :add_port, 'POST  /interfaces/:uuid/ports'
    include_examples 'test_method', :remove_port, 'DELETE  /interfaces/:uuid/ports'
  end

  describe VNetAPIClient::IpLease do
    include_examples 'test_method', :attach,
                     'PUT  /ip_leases/:uuid/attach'
    include_examples 'test_method', :release,
                     'PUT  /ip_leases/:uuid/release'
  end

  describe VNetAPIClient::IpRangeGroup do
    include_examples 'test_method', :add_range,
                     'POST  /ip_range_groups/:ip_range_group_uuid/ip_ranges'
  end

  describe VNetAPIClient::LeasePolicy do
    include_examples 'test_method', :add_lease,
                     'POST  /lease_policies/:uuid/ip_leases'
  end

  describe VNetAPIClient::MacRangeGroup do
    include_examples 'test_method', :add_range,
                     'POST  /mac_range_groups/:mac_range_group_uuid/mac_ranges'
  end

  describe VNetAPIClient::Translation do
    include_examples 'test_method', :add_static_address,
                     'POST  /translations/:uuid/static_address'
    include_examples 'test_method', :remove_static_address,
                     'DELETE  /translations/:uuid/static_address'
  end

  describe VNetAPIClient::Filter do
    include_examples 'test_method', :add_filter_static,
                     'POST  /filters/:uuid/static'
    include_examples 'test_method', :remove_filter_static,
                     'DELETE  /filters/:uuid/static'
    include_examples 'test_method', :show_filter_static,
                     'GET  /filters/static/'
    include_examples 'test_method', :show_filter_static_by_uuid,
                     'GET  /filters/static/:uuid'
  end
  #
  # Finally we make sure that no non standard routes are left untested
  #
  it "has implemented and tested all routes in the OpenVNet WebAPI" do
    if ! non_standard_routes.empty?
      raise "The following routes were not tested and might not be implemented:\n%s" %
        non_standard_routes.join("\n")
    end
  end
end

