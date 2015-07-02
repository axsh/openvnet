# -*- coding: utf-8 -*-

require 'net/http'
require 'json'


module VNetAPIClient
  def self.uri=(u)
    ApiResource.api_uri = u
  end

  def self.version=(v)
    ApiResource.api_version = v
  end

  def self.format=(f)
    ApiResource.api_format = f
  end
end

# Set default values
VNetAPIClient.uri = 'http://localhost:9101'
VNetAPIClient.format = :json
