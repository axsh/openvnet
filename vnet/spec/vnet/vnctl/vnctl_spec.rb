
# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
require 'yaml'

def app
  Vnet::Endpoints::V10::VnetAPI
end

$LOAD_PATH.unshift File.expand_path('../../../../../vnctl/lib', __FILE__)

require 'thor'
require 'vnctl'


describe 'vnctl' do
  it 'has exactly the same parameters as the webapi' do
    # We use the YAML format because it has support for ruby ranges.
    # Json would create a giant array of all possible tcp ports for some paramters
    get('browse', format: :yaml)
    routes = YAML.load(last_response.body)

    webapi_post_datapaths = routes.find { |r| r[:route] == 'POST  /datapaths' }
    cli_add_datapath = Vnctl::Cli::Datapath.all_tasks["add"]

    webapi_post_datapaths[:parameters].each do |param|
      expect(cli_add_datapath.options).to have_key(param[:name])
    end
  end
end
