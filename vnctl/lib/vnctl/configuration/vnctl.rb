# -*- coding: utf-8 -*-

module Vnctl::Configuration
  class Vnctl < Fuguta::Configuration
    param :webapi_uri, :default => '127.0.0.1'
    param :webapi_port, :default => 9090
    param :webapi_version, :default => '1.0'
    param :webapi_protocol, :default => 'http'
    param :output_format, :default => 'yml'

    def validate(errors)
      output_formats = ['yml', 'json']
      unless output_formats.member?(output_format)
        errors << "\"%s\" is not a valid output_format. Must be one of %s" %
          [output_format, output_formats.inspect]
      end
    end
  end
end
