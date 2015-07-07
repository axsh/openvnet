# -*- coding: utf-8 -*-
require 'spec_helper'

def app
  Vnet::Endpoints::V10::VnetAPI
end

include Rack::Test::Methods
api_specs = YAML.load(get("browse", format: :yaml).body)

#TODO: Freaking optimize this. :)
expected_classes = api_specs.map { |api_spec|
  underscored = api_spec[:route].split('/')[1].chomp('s')
  next if underscored == 'browse'

  underscored.split('_').collect!{ |w| w.capitalize }.join
}.uniq.compact

describe VNetAPIClient do
  expected_classes.each do |klass|
    describe klass do

      it "exists" do
        VNetAPIClient.const_get(klass)
      end

    end
  end
end

