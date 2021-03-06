# -*- coding: utf-8 -*-

require 'json'
require 'yaml'

require 'sinatra/respond_with'
require 'sinatra/namespace'
require 'sinatra/json'
require 'sinatra/hashfix'

# common setup for Vnet API Sinatra App. Based on the same file form Wakame-vdc
module Sinatra
  module VnetAPISetup
    # Returns deserialized hash from HTTP body. Serialization fromat
    # is guessed from content type header. The query string params
    # is returned if none of content type header is in HTTP headers.
    # This method is called only when the request method is POST.

    DEFAULT_OUTPUT_CONTENT_TYPE='application/json'

    BODY_PARSER = {
      'application/json' => proc { |body| ::JSON.load(body) },
      'text/json' => proc { |body| ::JSON.load(body) },
      'application/yaml' => proc { |body| ::YAML.load(body) },
      'text/yaml' => proc { |body| ::YAML.load(body) },
    }


    DO= proc {
      disable :sessions
      enable :logging

      register Sinatra::RespondWith
      register Sinatra::Namespace
      register Sinatra::Hashfix

      set :show_exceptions, false

      # avoid using Sinatra::JSON builtin encoder.
      set :json_encoder, ::JSON

      # remove trailing extension from URI and add mapped mime types to
      # http accept header. This helps to use file extension in URI with Sinatra::Namespace.
      before do
        rpi = request.path_info.sub(%r{\.([^\./]+)$}, '')
        ext = $1
        if ext
          (settings.mime_types(ext) || []).each.each { |i|
            request.accept.unshift(i)
          }
          request.path_info = rpi
        else
          request.accept.unshift(DEFAULT_OUTPUT_CONTENT_TYPE)
        end
      end

      # merge request body data into @params.
      before do
        next if !(request.content_length.to_i > 0)
        parser = BODY_PARSER[(request.content_type || request.preferred_type)]
        hash = if parser.nil?
                 # ActiveResource gives the one level nested hash which has
                 # {'something key'=>real_params} so that dummy key is assinged here.
                 {:dummy=>@params}
               else
                 begin
                   parser.call(request.body)
                 rescue => e
                   error(400, 'Invalid request body.')
                 end
               end

        @params.merge!(hash.values.first)
      end

      error(Vnet::Endpoints::Errors::APIError) do |boom|
        logger.error("API Error: #{request.path_info} -> #{boom.class}: #{boom.message} (#{boom.backtrace.first})")
        status(boom.http_status)
        respond_with({:error=>boom.class.to_s, :message=>boom.message, :code=>boom.error_code})
      end

      error do |boom|
        logger.error("API Error: #{request.path_info} -> #{boom.class}: #{boom.message} (#{boom.backtrace.first})")
        respond_with({:error=>boom.class.to_s, :message=>boom.message, :code=>'500'})
      end
    }

    def self.registered(app)
      app.class_eval &DO

      app.configure :development do
        require 'sinatra/reloader'
        app.register Sinatra::Reloader

        app.before do
          #logger.info "header: #{request.inspect}"
          logger.info "params: #{@params.inspect}"
        end
      end
    end
  end
end
